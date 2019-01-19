---
layout: post
date: 2019-01-18
title: State of WebGHC, January 2019
author: Will Fancher
---

WebGHC has undergone some significant improvements in the past year. Time has been quite scarce for all those involved, but we've managed to eek out some really useful progress. Special thanks to Dave Laing, Divam, and Moritz Angerman. They are responsible for a variety of advancements, such as build system refactors, `webabi` implementation, and toolchain fixes and upgrades.

I'm writing this now because WebGHC has recently reached a surprisingly usable state. You can use it to compile most Haskell packages (as long as they don't use Template Haskell), and run their executables in both NodeJS and the browser. For the most part, runtime errors from our implementation seem to be quite rare. Divam and Moritz implemented a JSaddle backend, so GHCJS apps that perform nontrivial DOM interaction via JSaddle are compiling to WebAssembly with trivial changes, and running quite well in the browser. Here's a table of some of the projects we've run, notably including projects built with both Reflex-DOM and Miso:

|                    | Wasm                                                  | Size | Shrunk | GHCJS                                                  | Size | Shrunk | Lib    |
|-------------------:|:-----------------------------------------------------:|:----:|:------:|:------------------------------------------------------:|:----:|:------:|:------:|
| **reflex-todomvc** | [link](/examples/2019-01-18/wasm-app-reflex-todomvc/) | 8.8M | 1.9M   | [link](/examples/2019-01-18/ghcjs-app-reflex-todomvc/) | 5.2M | 346K   | Reflex |
| **drag-and-drop**  | [link](/examples/2019-01-18/wasm-app-draganddrop/)    | 7.5M | 1.7M   | [link](/examples/2019-01-18/ghcjs-app-draganddrop/)    | 3.8M | 245K   | Reflex |
| **keyboard**       | [link](/examples/2019-01-18/wasm-app-keyboard/)       | 7.4M | 1.7M   | [link](/examples/2019-01-18/ghcjs-app-keyboard/)       | 3.8M | 240M   | Reflex |
| **nasa-pod**       | [link](/examples/2019-01-18/wasm-app-nasapod/)        | 8.6M | 1.9M   | [link](/examples/2019-01-18/ghcjs-app-nasapod/)        | 5.6M | 381K   | Reflex |
| **othello**        | [link](/examples/2019-01-18/wasm-app-othello/)        | 8.6M | 1.8M   | [link](/examples/2019-01-18/ghcjs-app-othello/)        | 5.1M | 332K   | Reflex |
| **todo-mvc**       | [link](/examples/2019-01-18/wasm-app-todo-mvc/)       | 5.4M | 1.4M   | [link](/examples/2019-01-18/ghcjs-app-todo-mvc/)       | 2.2M | 255K   | Miso   |
| **2048**           | [link](/examples/2019-01-18/wasm-app-2048/)           | 5.5M | 1.5M   | [link](/examples/2019-01-18/ghcjs-app-2048/)           | 2.2M | 252K   | Miso   |
| **flatris**        | [link](/examples/2019-01-18/wasm-app-flatris/)        | 6.0M | 1.6M   | [link](/examples/2019-01-18/ghcjs-app-flatris/)        | 3.4M | 376K   | Miso   |
| **mario**          | [link](/examples/2019-01-18/wasm-app-mario/)          | 5.3M | 1.5M   | [link](/examples/2019-01-18/ghcjs-app-mario/)          | 1.7M | 190K   | Miso   |
| **simple**         | [link](/examples/2019-01-18/wasm-app-simple/)         | 5.2M | 1.5M   | [link](/examples/2019-01-18/ghcjs-app-simple/)         | 1.6M | 184K   | Miso   |

"Shrunk" refers to gzipping files after running a size optimizer (binaryen's `wasm-opt -Oz` for WebAssembly, and Closure Compiler for GHCJS). I didn't figure out how to get Closure Compiler's advanced optimizations working for Miso, so those were only applied to the Reflex-DOM examples.

With so much working so well right now, I thought it'd be a good time to examine the current state of WebGHC. Bear in mind this is all my opinion; I can't speak for others who have worked on WebGHC.

---

First things first, I want to clarify that WebGHC is *not* intended to be a fork or otherwise derivative of GHC. The prime directive of WebGHC thus far has been to ensure its upstream-ability within the next 1-3 years. This is one of the reasons why we kept the RTS model and the codegen, and used an ordinary musl libc as a system runtime. I believe upstreaming is critical to Haskell's success on WebAssembly, as it will help ensure its performance, stability, and maintainability.

With that in mind, here are some ways I think WebGHC currently needs improvement:

- You must enable `SharedArrayBuffer` in your browser to try it out, unless you use Chrome. We use `SharedArrayBuffer` to allow the RTS to block on certain actions, so that we don't have to rewrite large portions of the RTS, which would compromise upstream-ability. I am sad that this features hasn't seen widespread re-enabling in most major browsers yet, but the fact that Chrome has done it makes me feel a lot better. I'm fairly confident that this feature will come back.
- Binary size hasn't reached our goal. After shrinking, binaries are almost an order of magnitude larger than I'd like for them to be. Before shrinking, we're pretty close to GHCJS, but still much farther than I'd like to be. For instance, the `reflex-todomvc` WebAssembly binary is 8.8M. This is a dramatic improvement from where we were a few months ago (by shear luck, upgrading the toolchain to newer versions of everything magically improved binary sizes x8), but we still have more to go. We do have some ideas on how to improve this though, such as moving to the LLVM backend once either it has tail call support on WebAssembly, or we shim it in by emitting ad-hoc trampolines from `ghccc` tail calls.
- Building this toolchain isn't as easy as I'd like. You have to: 1) Build LLVM / Clang / LLD. 2) Build musl and compiler-rt. 3) Create a toolchain wrapper. 4) Build libiconv and GHC, the latter taking about an hour on my Threadripper 1950X. Moritz Angerman has some tools to help automate the manual process, and we have Nix expressions over at [wasm-cross](https://github.com/WebGHC/wasm-cross) to automate this fully and provide a binary cache.
- No Template Haskell support. This should be possible in the future by spawning an external interpreter in NodeJS for `-fexternal-interpreter`, but that's going to take some effort to work around WebAssembly's lack of code-as-memory.

Most of these are "usability" problems. It's just a little too difficult to *use* WebGHC right now. This isn't surprising. It's a new toolchain for a new platform, and it's kind of a wild west of tooling out there right now. For instance, Rust has a completely custom toolchain based on LLVM, which they've automated using their `rustup` and `cargo` tools. We've tried to stick to a fairly standard model of toolchain, which has made some things easier and some things harder. But overall, I'm optimistic that all of these issues seem reasonably fixable, given some time.

---

As for areas where I feel WebGHC is doing well:

- We get a fully featured runtime out of the gate. We don't have parallelism yet, but we do have cooperative concurrency, so most of `Control.Concurrent` works out of the box, which enables a lot of complicated projects. Reflex-DOM for instance, which makes *extensive* use of some of GHC's wilder RTS features, worked the first time we tried it. This required no RTS specialization, so there's no maintainability ghosts here. The GC even seems to be working.
- Tracking changes in GHC. Truthfully, the amount of GHC code we had to write is really minimal. We only needed to do one refactoring of compiler logic, and one refactoring of build system logic. Updating to new GHC versions has been a matter of a couple hours each time we've done it (thrice now).
- Minimal custom codegen / runtime. Currently zero changes have been made to the RTS or the codegen, except one codegen change that is arguably an improvement for all platforms. So WebGHC will get virtually all the benefits that native GHC gets from its ordinary development.
- By treating WebAssembly as a typical cross compilation target, we get a lot of infrastructure for free. C packages that support cross compilation will often be trivial to build for WebAssembly. We get to reuse GHC's cross compilation pipeline and build system. And Nixpkgs supports our toolchain almost out of the box. You can pretty easily build complicated projects like Reflex-DOM because the toolchain just does what other infrastructure expects.
- C code on Hackage will very often just work, as long as it only uses the system calls that we've implemented. There was an issue with the ordinary C FFI that we've *mostly* resolved, but there are still some cases that we simply can't fix due to WebAssembly's unusual restrictions on types. When these cases arise though, they can practically always be fixed by using `-XCApiFFI` instead. Some examples: 1) Aeson's `unescape_string.c` worked without any special effort. 2) We converted some of `bytestring`'s C FFI code to CApiFFI because they didn't provide enough type information to realize the type at the WebAssembly level.
- JSaddle allows us to run a large portion of GHCJS applications on WebAssembly extremely easily. More on this later.
- [`webabi`, our low level implementation of musl's syscall requirements](https://github.com/WebGHC/webabi), provides a fantastically modular and isolated runtime, so that high level concepts can remain in musl and GHC and get translated down into a bare bones ABI, just like they're used to on other platforms. It's a lot like a kernel. This ABI is fairly simple to implement, and can be totally isolated from the rest of the toolchain.

So although WebGHC isn't as easy to use as I'd like, it functions superbly well, at least for something at such an early stage, and it's extremely compatible with existing Haskell code and GHC updates. I think these successes are largely due to our prime directive; we've reused code like the RTS, we've isolated out-of-band work like `webabi` and `jsaddle-wasm`, and we've kept the differences between WebGHC and other GHC targets to nearly zero. As a result, we've gotten all the existing advantages of everything we reused and stayed close to.

---

A few other notes I feel I should mention:

- Relative performance is as of yet untested. I have reasonable expectations that this will beat GHCJS in most cases based on some extremely crude preliminary testing, and it should skyrocket whenever we switch to the LLVM backend. But it is currently effectively unmeasured.
- We conventionally use JSaddle for all JS interaction. This gives us instant compatibility with a *lot* of code written for GHCJS, like all of Reflex-DOM. This has a performance implication, in that we have to copy commands from a WebWorker back to the main thread to perform any JS calls, and copy responses back. But this has proven, at least on mobile devices with natively compiled Reflex-DOM, to be extremely negligible. It seems to me that this marshaling is extremely cheap compared to the actual DOM rendering the browser has to do following the command. I used the word "conventionally" because it's entirely possible to interact with JS more directly through the WebAssembly module system, but this is difficult and will require marshaling to reach the main thread anyway. Thus we have no plans to support the `JavaSciptFFI` extension.

---

So what's next? There's still plenty to do. I don't anticipate this work being in a state I'd want to actually upstream for a while. Here are a few things I think need to happen sooner rather than later, from most to least important.

- Start testing. We need to see what's broken, what's slow, and what doesn't build. Finding a way to benchmark the performance of this vs GHCJS and native GHC would be great.
- Switching to the LLVM backend is becoming more and more important. It is likely to improve both performance and codesize dramatically. As I mentioned above, doing this will require LLVM to implement tail calls on WebAssembly, either via an actual tail call feature in WebAssembly, or via emitting ad-hoc trampolines.
- Lots. Of. Cleanup. The Nix code in wasm-cross isn't exactly pretty. For instance, we could probably start upstreaming the WebAssembly platform to Nixpkgs so that we can remove all that redundant clutter from wasm-cross. Also, the FFI fix I mentioned above was implemented quite hastily, and could use some serious cleanup.
- Template Haskell. TH is a difficult concept for cross compilation, but luckily the target we're compiling to is itself host agnostic, so we can just run a NodeJS process to host the external interpreter. Doing this is going to be a challenge though.

---

So that's my perspective on WebGHC right now. I'm looking forward to the progress we'll make going forward, and I'm very happy with the progress we've made so far. Let me know if there's any particular parts of all of this that you'd like a dedicated blog post about!
