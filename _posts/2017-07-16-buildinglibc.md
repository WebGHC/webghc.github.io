---
title: If you build it...
date: 2017-07-16 00:00:01
---
## If you build it...
_GHC is directly dependent on some 'commonly available system resources'. A big one of which is libc. We'll go over building libc, and making the process repeatable with nix_

### A Tough Nut to Crack
libc is enormous. It provides ~1300 functions for helping progamming languages do meaningful work. It provides an interface for managing memory (malloc, free, etc.), string manipulation & analysis (strcpy, strcmp), efficient mathematics, and thread management.  
That's a lot to manage.  
We certainly don't want to just re-implement it for WebAssembly as part of this project. We'll want to compile someone else's implementation of of libc.  
However, this is a non-trivial task as that Webassembly is young and just can't support all the features that libc generally furnishes. For example, threading [just doesn't work in Webassembly as of right now](https://github.com/WebAssembly/design/blob/master/FutureFeatures.md). So, compiling a standalone libc implementation to WebAssembly would mean overcoming several challenges.  

1. Figuring out what parts of libc just absolutely are incompatible with WebAssembly
2. Determining what parts can't work as it stands, but can work with some adjustment
3. Implementing those adjustments
4. Re-creating the build process but with the proper exclusions and changes that can successfully build libc to WebAssembly
  
[GNU libc](https://www.gnu.org/software/libc/manual/) is about a half a million lines of code on its own. Granted, it is built to minimize assumptions about the platform it's running on in order to maximize portability and that comes with some overhead. There are more lightweight solutions out there.  
[Musl libc](https://www.musl-libc.org/) was built with simplicity in mind. It sits at ~60,000 lines of code and is still fully featured.  
We just need one of these to successfully compile to WebAssembly. As long as one does, the generated library will be portable. With either library, doing all of this on our own would be well...  
A lot to manage.  
If we could find anyone else who has worked on something similar and re-use an appreciable part of their work it would make this a much less daunting task.

### A Sledgehammer 
[Emscripten](https://github.com/kripken/emscripten) compiles LLVM to Javascript (specifically asm.js) with first class support for C/C++. In fact, Emscripten created a port of Musl libc that compiles to asm.js.  
Asm.js can be relatively easily compiled to WebAssembly, and many of Emscripten's collaborator's are directly involved in WebAssembly's design and development. Emscripten, rather nimbly, added support for WebAssembly pretty early on. As such, they had to port their port of libc to build to WebAssembly. Their ported port could serve this project.  
However, Emscripten is a huge dependency to add to our project. It has support for a lot of things we don't need (like compiling to asm.js), and it uses its own fork of LLVM's Clang (which their documentation refers to as fastcomp). It would be best to just be dependent on modern, mainstream Clang/LLVM (which has fairly workable WebAssembly support as of recently).  
We just want their libc port and its build process.

### An Upgrade through Downsizing
Emscripten is a great project, but it doesn't seem like it was designed to be [used as a library](https://wiki.haskell.org/GHC/As_a_library). It exists as a fairly massive python codebase, and doesn't have a nice `configure`, `make`, `make install` installation. It's a script that runs. When you try and ask it to compile some c code, it checks and makes sure it has access to a libc that's built to the target you specified. If it realizes it doesn't have access to a proper libc, it builds it on the fly and caches it for later use.  
Our goal was to mirror this process into simple, standalone, streamlined python code that builds their WebAssembly libc port using Clang 5 instead of fastcomp.  
In doing this we determined which submodules of libc to exclude entirely from the build, and which specific files needed to be excluded as well. Emscripten does, in fact, build something that is referred to as `libc` in its code. In this build, it excludes many libc math functions; instead opting to call out to native javascript math functions when targeting asm.js.  
When building for WebAssembly, Emscripten does not change this build. It instead builds two more libraries called `wasm_libc` and `wasm_libc_rt`. These libraries are essentially WebAssembly builds of the originally excluded math functions. Furthermore, Emscripten builds a separate module called `dlmalloc` to furnish memory management functions.  
In our build, we bundle all of these up together rather than treating them as separate to create our own `libc`.
In the end, our final python script that built our `libc` turned out like this.  
```python
import os, sys
from subprocess import Popen
def main():
    # entire libc folders that are ignored
    ignoredModules = ['ipc', 'passwd', 'thread', 'signal', 'sched', 'ipc', 'time', 'linux', 'aio', 'exit', 'legacy', 'mq', 'process', 'search', 'setjmp', 'env', 'ldso', 'conf']

    # specific files that are ignored
    ignoredFiles = ['getaddrinfo.c', 'getnameinfo.c', 'inet_addr.c', 'res_query.c', 'gai_strerror.c', 'proto.c', 'gethostbyaddr.c', 'gethostbyaddr_r.c', 'gethostbyname.c', 'gethostbyname2_r.c', 'gethostbyname_r.c', 'gethostbyname2.c', 'usleep.c', 'alarm.c', 'syscall.c', '_exit.c']

    # abs path to here
    rootpath = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))

    # abs path to libc code
    musl_srcdir = os.path.join(rootpath, 'emscripten', 'system', 'lib', 'libc', 'musl', 'src')

    # setup
    objs = os.path.join(rootpath, "obj")
    lib = os.path.join(rootpath, "lib")
    if not os.path.exists(objs):
        os.makedirs(objs)
    if not os.path.exists(lib):
        os.makedirs(lib)
    # get a ton of absolute paths that lead to the files we want to compile
    libc_files = [os.path.join(rootpath, "emscripten/system/lib/dlmalloc.c")]
    for dirpath, dirnames, filenames in os.walk(musl_srcdir):
      for f in filenames:
        if f.endswith('.c'):
          if f in ignoredFiles: continue
          dir_parts = os.path.split(dirpath)
          cancel = False
          for part in dir_parts:
            if part in ignoredModules:
              cancel = True
              break
          if not cancel:
            libc_files.append(os.path.join(musl_srcdir, dirpath, f))

    cc = os.getenv("CC")
    objectListing = []
    #build and execute the command a lot
    for f in libc_files:
        objectFile = os.path.join(objs, os.path.basename(f)[:-1]+'o')
        objectListing.append(objectFile)
        cmd = [cc, "-I", rootpath+"/emscripten/system/lib/libc/musl/src/internal", "-Os",
        "-Werror=implicit-function-declaration", "-Wno-return-type", "-Wno-parentheses",
        "-Wno-ignored-attributes", "-Wno-shift-count-overflow", "-Wno-shift-negative-value",
        "-Wno-dangling-else", "-Wno-unknown-pragmas", "-Wno-shift-op-parentheses", "-D", "__EMSCRIPTEN__",
        "-Wno-string-plus-int", "-Wno-logical-op-parentheses", "-Wno-bitwise-op-parentheses",
        "-Wno-visibility", "-Wno-pointer-sign", "-isystem"+rootpath+"/emscripten/system/include",
        "-isystem"+rootpath+"/emscripten/system/include/libc", "-v", "-isystem"+rootpath+"/emscripten/system/lib/libc/musl/arch/emscripten",
        "-c", "-o", objectFile, f]
        proc = Popen(cmd, stdout=sys.stdout)
        proc.communicate()
        if proc.returncode != 0:
            raise Exception('Command \'%s\' returned non-zero exit status %s' % (' '.join(cmd), proc.returncode))

    ar = os.getenv("AR")
    arProc = Popen([ar, "rcs", os.path.join(lib, "libc.a")] + objectListing)
    arProc.communicate()

if __name__ == '__main__':
    main()
    sys.exit(0)
```
This builds a wasm libc that is linkable with recent releases of LLVM's lld.
Note, we execute this in a Nix environment that intelligently wraps calls to different build tools, so our actual calls to CC come out with a few extra flags to make compilation work. In the end they look like this (the output name and the input name are the last arguments).
```bash
clang-6.0 -cc1 -triple x86_64-unknown-linux-gnu -emit-obj -disable-free -disable-llvm-verifier -discard-value-names -main-file-name shgetc.c -mrelocation-model pic -pic-level 2 -mthread-model posix -fmath-errno -masm-verbose -mconstructor-aliases -munwind-tables -fuse-init-array -target-cpu x86-64 -momit-leaf-frame-pointer -v -dwarf-column-info -debugger-tuning=gdb -coverage-notes-file ./wasm-syslib-builder/obj/shgetc.gcno -nostdsysteminc -resource-dir /nix/store/ac2bsf3rck79a8gl1zfpma2s0cw29p2d-clang/lib/clang/6.0.0 -isystem ./wasm-syslib-builder/emscripten/system/include -isystem ./wasm-syslib-builder/emscripten/system/include/libc -isystem ./wasm-syslib-builder/emscripten/system/lib/libc/musl/arch/emscripten -idirafter /nix/store/vrr9maj9lqj2xwndlx3kh07vhnc111i2-glibc-2.25-dev/include -idirafter /nix/store/ac2bsf3rck79a8gl1zfpma2s0cw29p2d-clang/lib/gcc/*/*/include-fixed -isystem /nix/store/gc396jp0zvkkj6gx05nxr6l290c1aivk-llvm/include -isystem /nix/store/c24pf8amzw30zs34l13agxdqqv2hfjv5-ncurses-6.0-dev/include -isystem /nix/store/wfiz5lx24rr3r6c70523zw5rxv4pg38z-zlib-1.2.11-dev/include -I ./wasm-syslib-builder/emscripten/system/lib/libc/musl/src/internal -D __EMSCRIPTEN__ -D _FORTIFY_SOURCE=2 -internal-isystem /nix/store/ac2bsf3rck79a8gl1zfpma2s0cw29p2d-clang/lib/clang/6.0.0/include -O2 -Werror=implicit-function-declaration -Wno-return-type -Wno-parentheses -Wno-ignored-attributes -Wno-shift-count-overflow -Wno-shift-negative-value -Wno-dangling-else -Wno-unknown-pragmas -Wno-shift-op-parentheses -Wno-string-plus-int -Wno-logical-op-parentheses -Wno-bitwise-op-parentheses -Wno-visibility -Wno-pointer-sign -Wformat -Wformat-security -Werror=format-security -fdebug-compilation-dir ./wasm-syslib-builder -ferror-limit 19 -fmessage-length 271 -fwrapv -stack-protector 2 -stack-protector-buffer-size 4 -fobjc-runtime=gcc -fdiagnostics-show-option -fcolor-diagnostics -vectorize-loops -vectorize-slp -o ./wasm-syslib-builder/obj/shgetc.o -x c ./wasm-syslib-builder/emscripten/system/lib/libc/musl/src/internal/shgetc.c
```
The code that includes this python is up at this commit of the [wasm-syslib-builder](https://github.com/WebGHC/wasm-syslib-builder/tree/541eb4abf0bc356d152cc40860f3982db06aefc1) repo.  

### MAKEing Everything Easier
