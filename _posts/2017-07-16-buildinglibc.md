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
Asm.js can be relatively easily compiled to WebAssembly, and many of Emscripten's collaborator's are directly involved in WebAssembly's design and development. Emscripten, rather nimbly, added support for WebAssembly pretty early on. As such, they had to port their port of libc to build to WebAssembly. 

### An Upgrade through Downsizing

### Nixing Inconsistency
