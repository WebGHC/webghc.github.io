## Roadmap
_This page is a work-in-progress and will be updated as the project develops._  
_For now, the calendar will just reflect dates for the 2017 Summer Term in accordance with the Haskell Summer of Code schedule (which this project will hopefully be a part of)_  

### Plan
This project will consist of three main phases. The first of which is extending GHC. This will involve defining a WebAssembly target in GHC for emitting LLVM, as well as finalizing the necessary nix expressions to build this extended version of GHC. The second phase would consist of ensuring the WebAssembly generated by LLVM is valid and callable from the browser. Two major potential issues are LLVM’s support for tailcalls and the GHC calling convention. It’s unclear whether it properly handles these things when targeting WebAssembly; WebAssembly doesn’t implement tailcalls, and the GHC calling convention is very unusual. The final phase is porting the runtime system. Parts of the RTS written in C may, with the aid of LLVM compilation tools, work without much additional work. Various other components, like syscalls, will need special attention.  

The minimum viable product for this project is a version of GHC that can produce valid WebAssembly that can be run in a browser. It will support an unthreaded runtime, awaiting WebAssembly’s threading implementation for the threaded runtime. The C FFI will be implemented via the same means as the C FFI with a native backend. Only essential syscalls will be implemented.

### Schedule
We plan to have a version of the GHC toolchain that has knowledge of an available, but non-functioning, WebAssembly backend by July 2. By the week of July 23, the project should be able to produce valid WebAssembly from Haskell code. The rest of the term will be spent porting the GHC RTS. From our preliminary research, we believe the first two main objectives should be able to be completed reasonably quickly (possibly ahead of schedule). The bulk of this project will then be spent on the final main objective.

### Calendar
In the following calendar, goals are intended to be completed by the week they are listed in.  
Main Objectives are in **bold**

Week | Goals
---- | -----
June 11 |
June 18 | Project website ported to Hakyll with improved layout
June 25 |
July 2  | **GHC building with WASM as a Target**
July 9  |
July 16 |
July 23 | **WebGHC producing valid WASM**
July 30 |
August 6 |
August 13 |
August 20 |
August 27 | **RTS working in WASM**