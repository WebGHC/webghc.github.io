---
title: Summer of Haskell outcomes and the Road Ahead
date: 2017-08-10 00:00:01
---
## Summer of Haskell Outcomes and the Road Ahead
_The project term for Summer of Haskell is coming to a close. We'll go over where we're at, our expected upcoming progress and our plan for the future._ 

### Current Position
For this project to be successful, three (oversimplified) tasks are essential. (This is, of course, not an exhaustive list of what actually needs to be done either)

1. Implement the necessary tweaks to the GHC build system to support WebAssembly
2. Put together a repeatable setup for cross-compiling GHC using LLVM/Clang
3. Put (2) and (1) together to successfully cross-compile GHC to WebAssembly, enhancing LLVM/Clang's support for WebAssembly when necessary. 

We've actually got (2) working. You can use our work to cross-compile GHC to ARM (aarch64-unknown-linux-gnu), and with a little elbow grease our work could be used to cross compile to RaspberryPi.
We've tackled a lot of work related to (1) and (3). As far as development is concerned the two are pretty intertwined. The development process goes pretty much like so.

1. Try to use our cross-compilation process to cross-compile GHC to Webassembly.
2. Find the step at which the build breaks.
3. Determine what makes this step in the build different from a build that targets ARM, and if the problem is with GHC or LLVM/Clang
4. Fix the problem (easy right?)
5. Repeat.

We've had some nice surprises over the course of developing this project. GHC's support for cross-compilation has, in some ways, been more robust than we initially though. Also, LLVM text IR from the LLVM version pinned by GHC's LLVM Backend is forward-compatible with trunk LLVM. These two facts have resulted in us having to do far less direct manual labor with getting the runtime to build than we initially expected.  
Our major issues over the course of this project have stemmed from four unfortunate truths. 
1. While GHC's setup for cross-compilation is very functional, it isn't perfect and can sometimes be hard to debug.
2. WebAssembly represents a very unique paradigm, and making traditional cross-compilation tools/strategies target it sometimes results in unexpected challenges.
3. Webassembly itself is very young.
4. LLVM/Clang's support for WebAssembly is even younger. It is not fully featured like Clang's support for other targets, and is unstable.

Despite these issues, we've generally been able to solve problems as they come to us and make stable forward progess (not with _quite_ the speed we would've initially hoped for unfortunately).  
The WebAssembly team has been very helpful and informative throughout this project. In fact, much of the core WebAssembly Team also works directly on developing LLVM/Clang's WebAssembly support so they've been able to help us with pure WebAssembly related issues and Clang related issues (this can be a double-edged sword however since their efforts are split). 

Our current blocking issue in the build process can be found [here](https://bugs.llvm.org/show_bug.cgi?id=34544).

## Moving Forward
We didn't expect this project to be at a 'finished' state at the end of the term, but we did hope to reach a higher stage of completion.   
That said, the main contributors to this project (myself and my project mentor) are both personally committed to seeing WebGHC become production-ready, and plan to dedicate similar amounts of time to the project after the term as during the term. 
Here are some of the next major checkpoints for the project
1. Get the GHC build process to complete successfully for a cross compilation targeting WebAssembly.
2. Implement the syscalls necessary for a Haskell 'hello world' to work using WebGHC and ensure WebGHC actually produces working WebAssembly.
3. Implement all remaining syscalls.
4. Package up WebGHC in a way that is easy-to-use for non-nix users.
5. Get advanced features like Template Haskell working
6. Build up higher-level, useful development software on and around WebGHC

Getting the build to complete will produce a 'valid' GHC stage one executable, but not a working one. The GHC RTS needs to interface with working syscalls. Syscalls will be implemented once cross compilation build process is mastered. Therefore, as of right now, (1) and (2) are our main priorities in the short term. 

## Outcomes
As a part of the program I (the student developer on WebGHC) have become far more familiar wth (and involved in) the Haskell community, and the open source development community in general. With my time spent familiarizing myself with GHC, I've gained an increased ability to contribute to GHC in the future and an improved understanding of how the language actually works.  
My time learning about and working with Nix, and NixOS has further enhanced my ability to produce useful software in a functional paradigm. I've also learned a good deal about LLVM, and WebAssembly.

In all, WebGHC's participation in the Summer of Haskell has been a resounding success with one exception. The raw number of lines of code I've produced is still too low for my liking, this will be resolved as the project moves forward and steps like syscall implementation are reached.  

I look forward to continuing work on the project.
