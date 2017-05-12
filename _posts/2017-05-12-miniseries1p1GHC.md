---
title: _Learning by Example_ Blog Miniseries<br>Part 1 - GHC
date: 2017-05-12 00:00:01
---
## _Learning by Example_ Blog Miniseries<br>Part 1 - GHC
_In this post we'll introduce this miniseries, run some Haskell code manually, and see what we can learn about GHC's inner workings from there._

### Introduction
Before diving into full on research of the inner workings of GHC and other topics necessary to the completion of this project, it makes sense to take some time to familiarize ourselves with the tools we plan on using. In particular, how to use them on the most basic way. It doesn't make sense to try and develop software on top of tools we haven't used. Furthermore, we stand to gain quite a bit of practical knowledge in taking this baby step. The results of these exercises will be referenced (and further discussed) in several future blog posts.  

Since this project's crucial functionality lives at a relatively low-level, we will be focusing on the low-level tooling and concepts. If you're not really familiar with what compilers, assemblers, and linkers are, how they interact, or what they each generally produce, you'll want to take some time to read up on them now.

Also, many of these examples expect you to have things like the gcc, LLVM, or WebAssembly toolchains built, installed, and working on your machine. As we go along, I'll point you in towards directions for accomplishing these tasks. If you can't get something to work, just read along for now and rest assured that proper building and installation of large projects ***is not*** an easy task to take on without the proper tools. In a shortly upcoming blog post I'll show you how to use Nix to install and use everything you need for this project the Nix content just isn't quite ready yet. You'll be able to come back and run things for yourself if you wish.

### Preparation
You'll need gcc and the Haskell Platform installed on your system to step through this example. If you don't already have gcc, simple installation instructions for your system can easily be found via a google search. The Haskell platform is easily installed by following the instructions on [this page](https://www.haskell.org/platform/).

### The Steps
1. Go ahead and create an `example` project folder somewhere.
2. In this folder make a `tmp` sub-folder.  
3. Next, make a `helloworld.hs` file in the project root and put the line `main = putStrLn "Hello, World!"` in it.
4. In the project root

### Discussion
