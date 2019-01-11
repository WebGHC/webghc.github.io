---
title: Learning from GHC
date: 2017-05-12 00:00:01
layout: post
author: Michael Vogelsang
---

_In this post we'll run some Haskell code manually, link some object files manually, and see what we can learn about GHC's inner workings from there._

### Introduction
Before diving into full on research of the inner workings of GHC and other topics necessary to the completion of this project, it makes sense to take some time to familiarize ourselves with the tools we plan on using. It doesn't make sense to try and develop software on top of tools we haven't used. In particular, a more exacting examination of the more mundane usages of these tools is in order. We stand to gain quite a bit of practical knowledge in taking this baby step.

Since this project's crucial functionality lives at a relatively low-level, we will be focusing on the low-level tooling and concepts. If you're not really familiar with what compilers, assemblers, and linkers are, how they interact, or what they each generally produce, you'll want to take some time to read up on them now.

Also, it is often expected for you to have things like the gcc, LLVM, or WebAssembly toolchains built, installed, and working on your machine. As we go along, I'll point you towards directions for accomplishing these tasks. If you can't get something to work, just read along for now and rest assured that proper building and installation of large projects ***is not*** an easy task to take on without the proper tools. In a shortly upcoming blog post I'll show you how to use Nix to install and use everything you need for this project. The Nix content just isn't quite ready yet. You'll be able to come back and run things for yourself if you wish.

### Preparation
You'll need gcc and the Haskell Platform installed on your system to step through this example. If you don't already have gcc, simple installation instructions for your system can easily be found via a google search. The Haskell platform is easily installed by following the instructions on [this page](https://www.haskell.org/platform/).

### The Steps
1. Go ahead and create an `example` project folder somewhere.
2. In this folder make a `tmp` sub-folder.
3. Next, make a `helloworld.hs` file in the project root
and put the line `main = putStrLn "Hello, World!"` in it.
4. In the project root run
`ghc -keep-tmp-files -tmpdir ./tmp -o helloworld  helloworld.hs -v3`
You should end up with a long, verbose output detailing GHC's efforts to compile your file to an executable format. Don't clear your terminal after running this. You'll need some of this output later. The last bits of this output should look something like this (note that some of the lines are **very** long).
```bash
*** C Compiler:
/usr/bin/gcc -fno-stack-protector -DTABLES_NEXT_TO_CODE -c tmp/ghcec73_0/ghc_4.c -o tmp/ghcec73_0/ghc_5.o -I/usr/lib/ghc/include
*** C Compiler:
/usr/bin/gcc -fno-stack-protector -DTABLES_NEXT_TO_CODE -c tmp/ghcec73_0/ghc_7.s -o tmp/ghcec73_0/ghc_8.o -I/usr/lib/ghc/include
*** Linker:
/usr/bin/gcc -fno-stack-protector -DTABLES_NEXT_TO_CODE '-Wl,--hash-size=31' -Wl,--reduce-memory-overheads -Wl,--no-as-needed -o helloworld helloworld.o -L/usr/lib/ghc/base_HQfYBxpPvuw8OunzQu6JGM -L/usr/lib/ghc/integ_2aU3IZNMF9a7mQ0OzsZ0dS -L/usr/lib/ghc/ghcpr_8TmvWUcS1U1IKHT0levwg3 -L/usr/lib/ghc/rts tmp/ghcec73_0/ghc_5.o tmp/ghcec73_0/ghc_8.o -Wl,-u,ghczmprim_GHCziTypes_Izh_static_info -Wl,-u,ghczmprim_GHCziTypes_Czh_static_info -Wl,-u,ghczmprim_GHCziTypes_Fzh_static_info -Wl,-u,ghczmprim_GHCziTypes_Dzh_static_info -Wl,-u,base_GHCziPtr_Ptr_static_info -Wl,-u,ghczmprim_GHCziTypes_Wzh_static_info -Wl,-u,base_GHCziInt_I8zh_static_info -Wl,-u,base_GHCziInt_I16zh_static_info -Wl,-u,base_GHCziInt_I32zh_static_info -Wl,-u,base_GHCziInt_I64zh_static_info -Wl,-u,base_GHCziWord_W8zh_static_info -Wl,-u,base_GHCziWord_W16zh_static_info -Wl,-u,base_GHCziWord_W32zh_static_info -Wl,-u,base_GHCziWord_W64zh_static_info -Wl,-u,base_GHCziStable_StablePtr_static_info -Wl,-u,ghczmprim_GHCziTypes_Izh_con_info -Wl,-u,ghczmprim_GHCziTypes_Czh_con_info -Wl,-u,ghczmprim_GHCziTypes_Fzh_con_info -Wl,-u,ghczmprim_GHCziTypes_Dzh_con_info -Wl,-u,base_GHCziPtr_Ptr_con_info -Wl,-u,base_GHCziPtr_FunPtr_con_info -Wl,-u,base_GHCziStable_StablePtr_con_info -Wl,-u,ghczmprim_GHCziTypes_False_closure -Wl,-u,ghczmprim_GHCziTypes_True_closure -Wl,-u,base_GHCziPack_unpackCString_closure -Wl,-u,base_GHCziIOziException_stackOverflow_closure -Wl,-u,base_GHCziIOziException_heapOverflow_closure -Wl,-u,base_ControlziExceptionziBase_nonTermination_closure -Wl,-u,base_GHCziIOziException_blockedIndefinitelyOnMVar_closure -Wl,-u,base_GHCziIOziException_blockedIndefinitelyOnSTM_closure -Wl,-u,base_GHCziIOziException_allocationLimitExceeded_closure -Wl,-u,base_ControlziExceptionziBase_nestedAtomically_closure -Wl,-u,base_GHCziEventziThread_blockedOnBadFD_closure -Wl,-u,base_GHCziWeak_runFinalizzerBatch_closure -Wl,-u,base_GHCziTopHandler_flushStdHandles_closure -Wl,-u,base_GHCziTopHandler_runIO_closure -Wl,-u,base_GHCziTopHandler_runNonIO_closure -Wl,-u,base_GHCziConcziIO_ensureIOManagerIsRunning_closure -Wl,-u,base_GHCziConcziIO_ioManagerCapabilitiesChanged_closure -Wl,-u,base_GHCziConcziSync_runSparks_closure -Wl,-u,base_GHCziConcziSignal_runHandlersPtr_closure -lHSbase-4.8.2.0-HQfYBxpPvuw8OunzQu6JGM -lHSinteger-gmp-1.0.0.0-2aU3IZNMF9a7mQ0OzsZ0dS -lHSghc-prim-0.4.0.0-8TmvWUcS1U1IKHT0levwg3 -lHSrts -lgmp -lm -lrt -ldl -lffi
link: done
```
You should now also have a `helloworld.o` object file, a `helloworld.hi` interface file, and a `helloworld` executable file. In addition there should be a new sub-folder in your `temp` folder. It should contain eight similarly named files whose names all end in numbers. From here on we'll refer to each of these as `tmp1` - `tmp8`; `tmp1` being the lowest numbered file in the `tmp` folder.
5. In the project root run `./helloworld`. You should see `Hello, World!` pop up on the command line.
6. Delete the `helloworld` executable file.
7. Copy the line from the verbose output that immediately follows `*** Linker:`. Paste and run the command. A working `helloworld` executable should appear in the project root.

### Discussion
So what was gained from this exercise? Trivially, we've managed to compile and run some Haskell code. In step 4 we called out to GHC to compile our Haskell code, but specified that it not delete any of the temporary files it creates in the process, and to place temporary files in our local project folder. Notably we got a linkable `helloworld.o` object file in return. We also received the command that is used to successfully link it (the command we copied in step 7). We verified running this command outside of the context that it was originally called in still results in successful completion.

Further examination of the step 7 command yields some interesting information. Let's go over some of its key parts. However, this command is very long and unwieldy. I'll keep repasting the command as we go, each time removing the parts we've covered. I recommend pasting each instance of the command into a text editor with word-wrap enabled to see the sections of the command more clearly.

The command in its unchanged form is as so.
```bash
/usr/bin/gcc -fno-stack-protector -DTABLES_NEXT_TO_CODE '-Wl,--hash-size=31' -Wl,--reduce-memory-overheads -Wl,--no-as-needed -o helloworld helloworld.o -L/usr/lib/ghc/base_HQfYBxpPvuw8OunzQu6JGM -L/usr/lib/ghc/integ_2aU3IZNMF9a7mQ0OzsZ0dS -L/usr/lib/ghc/ghcpr_8TmvWUcS1U1IKHT0levwg3 -L/usr/lib/ghc/rts tmp/ghcec73_0/ghc_5.o tmp/ghcec73_0/ghc_8.o -Wl,-u,ghczmprim_GHCziTypes_Izh_static_info -Wl,-u,ghczmprim_GHCziTypes_Czh_static_info -Wl,-u,ghczmprim_GHCziTypes_Fzh_static_info -Wl,-u,ghczmprim_GHCziTypes_Dzh_static_info -Wl,-u,base_GHCziPtr_Ptr_static_info -Wl,-u,ghczmprim_GHCziTypes_Wzh_static_info -Wl,-u,base_GHCziInt_I8zh_static_info -Wl,-u,base_GHCziInt_I16zh_static_info -Wl,-u,base_GHCziInt_I32zh_static_info -Wl,-u,base_GHCziInt_I64zh_static_info -Wl,-u,base_GHCziWord_W8zh_static_info -Wl,-u,base_GHCziWord_W16zh_static_info -Wl,-u,base_GHCziWord_W32zh_static_info -Wl,-u,base_GHCziWord_W64zh_static_info -Wl,-u,base_GHCziStable_StablePtr_static_info -Wl,-u,ghczmprim_GHCziTypes_Izh_con_info -Wl,-u,ghczmprim_GHCziTypes_Czh_con_info -Wl,-u,ghczmprim_GHCziTypes_Fzh_con_info -Wl,-u,ghczmprim_GHCziTypes_Dzh_con_info -Wl,-u,base_GHCziPtr_Ptr_con_info -Wl,-u,base_GHCziPtr_FunPtr_con_info -Wl,-u,base_GHCziStable_StablePtr_con_info -Wl,-u,ghczmprim_GHCziTypes_False_closure -Wl,-u,ghczmprim_GHCziTypes_True_closure -Wl,-u,base_GHCziPack_unpackCString_closure -Wl,-u,base_GHCziIOziException_stackOverflow_closure -Wl,-u,base_GHCziIOziException_heapOverflow_closure -Wl,-u,base_ControlziExceptionziBase_nonTermination_closure -Wl,-u,base_GHCziIOziException_blockedIndefinitelyOnMVar_closure -Wl,-u,base_GHCziIOziException_blockedIndefinitelyOnSTM_closure -Wl,-u,base_GHCziIOziException_allocationLimitExceeded_closure -Wl,-u,base_ControlziExceptionziBase_nestedAtomically_closure -Wl,-u,base_GHCziEventziThread_blockedOnBadFD_closure -Wl,-u,base_GHCziWeak_runFinalizzerBatch_closure -Wl,-u,base_GHCziTopHandler_flushStdHandles_closure -Wl,-u,base_GHCziTopHandler_runIO_closure -Wl,-u,base_GHCziTopHandler_runNonIO_closure -Wl,-u,base_GHCziConcziIO_ensureIOManagerIsRunning_closure -Wl,-u,base_GHCziConcziIO_ioManagerCapabilitiesChanged_closure -Wl,-u,base_GHCziConcziSync_runSparks_closure -Wl,-u,base_GHCziConcziSignal_runHandlersPtr_closure -lHSbase-4.8.2.0-HQfYBxpPvuw8OunzQu6JGM -lHSinteger-gmp-1.0.0.0-2aU3IZNMF9a7mQ0OzsZ0dS -lHSghc-prim-0.4.0.0-8TmvWUcS1U1IKHT0levwg3 -lHSrts -lgmp -lm -lrt -ldl -lffi
```
This command is, again, using gcc to link our object file. Gcc (contrary to the belief of some), is not just a compiler. It is an interface to a variety of build tools. We're telling gcc to process an object file so it knows it needs to reach out to its linker, ld, to link this object file against other object files and libraries to produce a runnable result. With some extra effort we could actually translate this command into a call to ld that would produce the same result. In fact, the gcc option `-Wl` means 'pass the following option directly to the linker'. The linker option, '-u', tells the linker to 'unlink' a symbol. This is a way of triggering linking of other libraries. So within this command all the sections of the form `-Wl,-u,_Somesymbol_` are essentially telling the linker to grab more information.
Removing all of these bits yields this shortened form.
```bash
/usr/bin/gcc -fno-stack-protector -DTABLES_NEXT_TO_CODE '-Wl,--hash-size=31' -Wl,--reduce-memory-overheads -Wl,--no-as-needed -o helloworld helloworld.o -L/usr/lib/ghc/base_HQfYBxpPvuw8OunzQu6JGM -L/usr/lib/ghc/integ_2aU3IZNMF9a7mQ0OzsZ0dS -L/usr/lib/ghc/ghcpr_8TmvWUcS1U1IKHT0levwg3 -L/usr/lib/ghc/rts tmp/ghcec73_0/ghc_5.o tmp/ghcec73_0/ghc_8.o -lHSbase-4.8.2.0-HQfYBxpPvuw8OunzQu6JGM -lHSinteger-gmp-1.0.0.0-2aU3IZNMF9a7mQ0OzsZ0dS -lHSghc-prim-0.4.0.0-8TmvWUcS1U1IKHT0levwg3 -lHSrts -lgmp -lm -lrt -ldl -lffi
```
This is already much more manageable. The `-L` (notice the case) command line option is a way of explicitly telling the linker to check specific directories for linkable libraries that you may list later in the command. If you look at each usage of this option, you'll notice they all specify a location in /usr/lib/ghc. All of these directives are ensuring that the linker will be able to find dependencies that ghc furnishes.
Removing those sections yields this.
```bash
/usr/bin/gcc -fno-stack-protector -DTABLES_NEXT_TO_CODE '-Wl,--hash-size=31' -Wl,--reduce-memory-overheads -Wl,--no-as-needed -o helloworld helloworld.o tmp/ghcec73_0/ghc_5.o tmp/ghcec73_0/ghc_8.o -lHSbase-4.8.2.0-HQfYBxpPvuw8OunzQu6JGM -lHSinteger-gmp-1.0.0.0-2aU3IZNMF9a7mQ0OzsZ0dS -lHSghc-prim-0.4.0.0-8TmvWUcS1U1IKHT0levwg3 -lHSrts -lgmp -lm -lrt -ldl -lffi
```
The section `-o helloworld helloworld.o` is simply saying 'process my file `helloworld.o` and give me the result in the file `helloworld`'.
Removing this yields the following.
```bash
/usr/bin/gcc -fno-stack-protector -DTABLES_NEXT_TO_CODE '-Wl,--hash-size=31' -Wl,--reduce-memory-overheads -Wl,--no-as-needed tmp/ghcec73_0/ghc_5.o tmp/ghcec73_0/ghc_8.o -lHSbase-4.8.2.0-HQfYBxpPvuw8OunzQu6JGM -lHSinteger-gmp-1.0.0.0-2aU3IZNMF9a7mQ0OzsZ0dS -lHSghc-prim-0.4.0.0-8TmvWUcS1U1IKHT0levwg3 -lHSrts -lgmp -lm -lrt -ldl -lffi
```
The section `tmp/ghcec73_0/ghc_5.o tmp/ghcec73_0/ghc_8.o` is a way of manually telling the linker to link against `tmp3` and `tmp6` once. Further examination of our project's `tmp` folder seems to indicate (by way of the file contents) that `tmp3.o` is directly derived from `tmp2.c`. The contents of `tmp2.c` are noteworthy.
```c
#include "Rts.h"
extern StgClosure ZCMain_main_closure;
int main(int argc, char *argv[])
{
 RtsConfig __conf = defaultRtsConfig;
 __conf.rts_opts_enabled = RtsOptsSafeOnly;
 __conf.rts_hs_main = rtsTrue;
 return hs_main(argc,argv,&ZCMain_main_closure,__conf);
}
```
It seems that GHC is dynamically generating a main function that serves to call into the Haskell program's main function. GHC creates, compiles, and links against this file when it is called upon to compile high-level code.
Moving on, we remove the calls to link against the temporary files from our command to produce the following.
```bash
/usr/bin/gcc -fno-stack-protector -DTABLES_NEXT_TO_CODE '-Wl,--hash-size=31' -Wl,--reduce-memory-overheads -Wl,--no-as-needed -lHSbase-4.8.2.0-HQfYBxpPvuw8OunzQu6JGM -lHSinteger-gmp-1.0.0.0-2aU3IZNMF9a7mQ0OzsZ0dS -lHSghc-prim-0.4.0.0-8TmvWUcS1U1IKHT0levwg3 -lHSrts -lgmp -lm -lrt -ldl -lffi
```
The `-l_argname_` command tells the linker to look in its list of reference directories for a library with the name of `lib_argname_.a` and link against it. The `-lm` directive tells the linker to use libm, which is a standard library that furnishes a variety of math functionalities. In fact libgmp, libm, librt, libdl, and libffi are all standard system libraries.
Then we get to the big one, libHSrts. This is the compiled representation of the GHC RTS. This is valuable because the concept of a runtime is hazily-defined for many, and the way a language actually implements the concept of a runtime is not guaranteed to be so clean. Here we are seeing for ourselves that if we want a working runtime, we need to link compiled Haskell code against a valid libHSrts (and the other necessary libraries). Looking into the origins of the other libraries being linked against (the ones preceding libHSrts) also yields valuable information. These libraries are [boot packages](https://ghc.haskell.org/trac/ghc/wiki/Commentary/Libraries). Boot packages meet a variety of needs; importantly, some of them are necessary for advanced stages of GHC build process.

We've unearthed quite a bit of information in this exercise that will be valuable in the future.

That's enough linker command analysis for now.
