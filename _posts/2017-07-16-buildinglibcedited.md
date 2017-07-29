---
title: If you build it... (revised 25 July 2017)
date: 2017-07-25 00:00:01
---
## If you build it... (revised 25 July 2017)
_GHC is directly dependent on some 'commonly available system resources'. Two of them are compiler-rt and libc. We'll cover how to build them to WebAssembly._  
_With these two libraries available, we should be able to compile C code to runnable WebAssembly. We'll go over what the process looks like to compile C code and run it in the browser._

### Setup
To be able to do any of this, you'll need a working build of a modern version of Clang (We're using Clang 6). If you don't have one, it's [easy enough to build Clang/LLVM yourself](https://clang.llvm.org/get_started.html). Once you've got those built, make sure to add the `bin` directories of LLVM and Clang to your `PATH`. clang, llvm-ar, lld, and llvm-config should all be able to be found using `which`.  
Set clang to be your environment's C compiler with `export CC="clang"`. Set default flags with `export CFLAGS="-target wasm32-unknown-unknown-wasm -nostdinc -nodefaultlibs -nostartfiles"`.  
As a sanity check, running `$CC $CFLAGS -v` should yield several lines of output, the first of which should look like this...  
```bash
clang version 6.0.0 
Target: wasm32-unknown-unknown-wasm
```
Go ahead and set the environment archiver with `export AR="llvm-ar"` and set the environment linker with `export LD="lld"`. Set linker default flags with `export LDFLAGS="-flavor wasm"`
You'll also need to know where your `llvm-config` binary lives. It should be in the bin directory of the location LLVM was installed to. `export LLVM_CONFIG=$(which llvm-config)`
For convenience, `export TARGET_TRIPLE=wasm32-unknown-unknown-wasm` (and yes that is technically a quadruple).
Finally, we're going to be building several projects. To make things easier, make a project directory called `wasmbuilds` and `export WASMBUILDS=<pathtowasmbuilds>/wasmbuilds`.  
Having all these environment variables set will make explaining the upcoming exercises much easier. Keep in mind that these variables are temporary, so all of this needs to be done in the same shell.  

compiler-rt needs to reference libc's headers, so we'll build and install libc and then do the same for compiler-rt. After that we'll use these libraries to compile some C code, and spin up a local server to see it run.  
Finally, remember to do all of this in the same shell since exported environment variables only exist in the session they were created in.  

### Libc
#### strategy
Libc is large. Re-implementing it ourselves would be arduous and foolish. We need to find an existing implementation, find out what parts can't work with WebAssembly, adjust the parts that can be ported to work with WebAssembly, and design an adjusted build process accodingly. If any other projects have done something like this, we should re-use their work.  
[GNU libc](https://www.gnu.org/software/libc/manual/) is about a half a million lines of code on its own. [Musl libc](https://www.musl-libc.org/) was built with simplicity in mind. It sits at ~60,000 lines of code and is still fully featured.  
[Emscripten](https://github.com/kripken/emscripten) compiles LLVM to Javascript (specifically asm.js) with first class support for C/C++. In fact, Emscripten created a port of Musl libc that compiles to asm.js. Asm.js can be relatively easily compiled to WebAssembly, and many of Emscripten's collaborator's are directly involved in WebAssembly's design and development. As such, Emscripten rather nimbly added support for WebAssembly pretty early on. In doing so, they ported their libc port to WebAssembly.  
Emscripten is a huge dependency to add to our project. It has support for a lot of things we don't need (like compiling to asm.js), and it uses its own fork of LLVM's Clang (which their documentation refers to as fastcomp). It would be best to just be dependent on modern, mainstream Clang/LLVM (which has fairly workable WebAssembly support as of recently).  
We just want their libc port and its build process.  
Emscripten exists as a fairly massive python codebase, and wasn't really designed to be [used as a library](https://wiki.haskell.org/GHC/As_a_library). The build process and application logic are intertwined. We extracted the libc build process into simplified, streamlined python code and then used that understandable python to create a Makefile. The original python code is available at [this commit](https://github.com/WebGHC/wasm-syslib-builder/tree/541eb4abf0bc356d152cc40860f3982db06aefc1) of the [wasm-syslib-builder repo](https://github.com/WebGHC/wasm-syslib-builder/) as `libbuild.py`.  

#### steps
executing the following commands should build libc to wasm without having to install Nix, or clone any of our repos.
1. `cd $WASMBUILDS`
2. `mkdir libc && mkdir libcbuilder` - libc is where the headers and libc.a will end up
3. `cd libcbuilder`
4. `curl -L https://github.com/kripken/emscripten/archive/3bfcf9cdf9cda7b6fc0a12f20a0103beee5b505a.tar.gz | tar zx` - we don't use emscripten as a dependency, but we do steal some of its files to build libc
5. `mv emscripten-3bfcf9cdf9cda7b6fc0a12f20a0103beee5b505a emscripten` - rename the repo to something reasonable
5. `git clone git@gist.github.com:38b603136e59d07b87b9654869d9f45d.git && mv 38b603136e59d07b87b9654869d9f45d/Makefile ./Makefile && rm -rf 38b603136e59d07b87b9654869d9f45d` - This is a slightly adjusted Makefile from the WebGHC wasm-syslib-builder repo. It just hardcodes the installation prefix to be based off of `$WASMBUILDS` and adds an explicit reference to `$CFLAGS`. 
6. `make` - builds the dependencies we want. If you don't care about watching things happend sequentially, and want things to go faster you can add the `-j <number of threads you desire> ` option.
7. `make install` - puts the libc headers and archive in the libc directory
8. `export CFLAGS=$CFLAGS"-I $WASMBUILDS/libc/include"` - add the libc headers to CC's search path. 
9. `export LDFLAGS=$LDFLAGS" -L $WASMBUILDS/libc/lib"` - add libc.a's location to the linker search path

### Compiler-rt
#### strategy
[Fully building compiler-rt](https://compiler-rt.llvm.org/) actually furnishes much more than one library, but doing all this takes extra effort. We haven't quite made the preparations to do this yet, so for now we'll just build what we need. We need compiler-rt's 'builtins'. The steps following show how to build just this part of compiler-rt

#### steps
1. `cd $WASMBUILDS`
2. `curl -L https://github.com/llvm-mirror/compiler-rt/archive/ecbdaaaa7a191059b66291b93f6874e7189e4ed9.tar.gz | tar zx` - pulls down a specific revision of compiler rt
3. `mv compiler-rt-ecbdaaaa7a191059b66291b93f6874e7189e4ed9 crtbuilder` -renames the compiler-rt folder to something reasonable
4. `mkdir compiler-rt && cd compiler-rt` - the actual compiler-rt library will end up here
5. `cmake -DLLVM_CONFIG_PATH=$LLVM_CONFIG -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=$TARGET_TRIPLE -DCOMPILER_RT_BAREMETAL_BUILD=TRUE -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=TRUE -DCMAKE_C_COMPILER_WORKS=1 --target ../crtbuilder/lib/builtins` - compiler-rt uses cmake, and specifies that you not try to build it from within it's own directory, so we call cmake from the destination directory
6. `make`
7. `mv ./lib/*/libclang_rt.builtins-*.a ./lib/libcompiler_rt.a` - move the archive somewhere we'd expect it, and rename it to something more reasonable
8. `export LDFLAGS=$LDFLAGS" -L $WASMBUILDS/compiler-rt/lib"` - add the compiler-rt archive's home to LDFLAGS

### Build and Run Something
### strategy
We'll do a simple example. If you have something like hserv, or [darkhttpd](https://unix4lyfe.org/darkhttpd/) installed you'll be able to easily spin up a local server and see the fruits of your efforts. Since darkhttpd is just a simple c compilation, and I'm already assuming you have clang, I'm going to assume you have it. we'll have a hardcoded index.html, and some hardcoded javascript that will fetch and instantiate our wasm module for us. We'll be able to see the result of our c code's `main` function printed to the console.
### steps
1. `cd $WASMBUILDS`
2. `mkdir site && cd site`
3. copy the following into a file named `index.html`
    ```html
		<!doctype html>
		<html>
		  <head>
		    <meta charset="utf-8"></meta>
		  </head>

		  <body>
		    <script src="wasm.js"></script>
		  </body>
		</html>
    ```
4. copy the following into a file named `wasm.js`
    ```Javascript
		var importObject = {
				    "env": {
				        "__eqtf2": () => {throw "NYI"},
				        "__extenddftf2": () => {throw "NYI"},
				        "__fixtfsi": () => {throw "NYI"},
				        "__fixunstfsi": () => {throw "NYI"},
				        "__floatsitf": () => {throw "NYI"},
				        "__floatunsitf": () => {throw "NYI"},
				        "getenv": () => {throw "NYI"},
				        "__lock": () => {throw "NYI"},
				        "__map_file": () => {throw "NYI"},
				        "__netf2": () => {throw "NYI"},
				        "sbrk": () => {throw "NYI"},
				        "__stack_chk_fail": () => {throw "NYI"},
				        "__stack_chk_guard": () => {throw "NYI"},
				        "__syscall140": () => {throw "NYI"},
				        "__syscall146": () => {throw "NYI"},
				        "__syscall6": () => {throw "NYI"},
				        "__syscall91": () => {throw "NYI"},
				        "__unlock": () => {throw "NYI"},
								"__unordtf2": () => {throw "NYI"},
								"__multf3": () => {throw "NYI"},
								"__addtf3": () => {throw "NYI"},
								"__subtf3": () => {throw "NYI"}
				    }
		};
				
		function fetchAndInstantiate(url, importObject) {
		  return fetch(url).then(response =>
		    response.arrayBuffer()
		  ).then(bytes =>
		    WebAssembly.instantiate(bytes, importObject)
		  ).then(results =>
		    results.instance
		  );
		}

		fetchAndInstantiate("main", importObject).then(function(instance) {
		    console.log(instance.exports);
				console.log(instance.exports.main());				
		});
    ```
5. make a file `main.c` with a `main` function that returns an int and takes no arguments. You can import libc headers! (make your first one simply `return 1` to make sure everything is working. You can change this and recompile as you wish)
6. `$CC $CFLAGS -c main.c -o main.o`
7. `$LD $LDFLAGS main.o -o main -lc -lcompiler_rt -error-limit=0 -allow-undefined -entry=main` - The `-allow-undefined` just helps make this work easily for now. Eventually we'll want to figure out which symbols we expect to be undefined, list them in a file, and use `--allow-undefined-file=<value>`. We'll expect to define these symbols using javascript in the Module instantiation process, but more on this later.
8. spin up your lightweight server in this directory. If you have darkhttpd it's just `darkhttpd .`. hserv is very similar.
9. open a browser and navigate to the local site! darkhttpd's should be `0.0.0.0:8080`. open developer tools, and refresh the page (I've rarely had errors on initial load that went away upon refresh). You should see the value returned by main in the console.
10. alter `main.c`, recompile, and relink to your desire
