---
title: If you build it... (revised 25 July 2017)
date: 2017-07-25 00:00:01
---
## If you build it...
_GHC is directly dependent on some 'commonly available system resources'. Two of them are compiler-rt and libc. We'll cover how to build them to WebAssembly._  
_With these two libraries available, we should be able to compile C code to runnable WebAssembly. We'll go over what the process looks like to compile C code and run it in the browser._

#### Setup
To be able to do any of this, you'll need a working build of a modern version of Clang (We're using Clang 6). If you don't have one, it's [easy enough to build it yourself](https://clang.llvm.org/get_started.html). Once you have it built, set it to be your environment's C compiler with `export CC="<yourpathtoclang>/clang --target=wasm32-unknown-unknown-wasm"`.  
As a sanity check, running `$CC -v` should yield several lines of output, the first of which should look like this...  
```bash
clang version 6.0.0 
Target: wasm32-unknown-unknown-wasm
```



### compiler-rt
### libc
