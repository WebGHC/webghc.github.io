---
title: A Gentle Introduction
date: 2017-05-12 00:00:00
---
## A Gentle Introduction
_In this post we'll explore what WebAssembly is, and why we want to bring Haskell to it._

### The Setup
One day, a new developer wants to build a website. They learn about [HTML](https://www.w3schools.com/html/), [CSS](https://www.w3schools.com/css/), and even how to [set up a basic web server](http://www.instructables.com/id/Set-up-your-very-own-Web-server/). They get their site up and running and everything is fantastic.  

That is, everything is fantastic until the developer realizes the website doesn't quite have enough _oomph_. The site needs to be more interactive, with capabilities that extend beyond those possible in CSS. It needs games; it needs to do nontrivial calculations on the client side; it needs to handle events and send HTTP requests on the fly. So, our humble developer learns [Javascript](https://www.w3schools.com/js/) to accomplish these tasks. The project is such a success that our developer goes out and hires a dev team to help keep up with bug fixes and feature requests. The project is growing and everything is fantastic.

Except everything isn't really fantastic. Our developer accomplished what was needed, but the final outcome was not what our developer really _wanted_. Our developer really wanted to make a more graphically intensive games, and have snappier client-side calculations. The dev team is great, but (as with many enterprise web applications) the codebase has grown large, and with that size has come a certain unwieldiness that our developer didn't expect. Our developer is plagued by some recurring thoughts.  
1. >_"It's hard to reason about the behavior of much of the codebase. New features, and even bug fixes, have unexpected effects on the system and often cause issues."_
2. >_"At this point, I'm really only comfortable making changes to code that I wrote, or writing new code that heavily relates to what I've already written."_
3. >_"Bug fixes and features seem to be taking longer and longer to implement. Development really is getting expensive."_
4. >_" It's great that Javascript lets me add advanced functionality to my site, but always writing in an asynchronous context is a pain. The language sure is full of a lot of [frustrating and confusing quirks](https://whydoesitsuck.com/why-does-javascript-suck/) too."_
5. >_"Now that the codebase is so large, dynamic typing is more of a curse than a blessing. A statically typed language with a fully-featured type system would be enormously helpful"_
6. >_"Between being an interpreted language and being limited to running in a single thread, Javascript really limits what I can do. I really would need a much faster language with access to multithreading to do what I really want."_
7. >_"Sending my computational logic to the client as text feels wasteful. I wish I could send it in a form closer to machine code. This would definitely help load times."_
8. >_"I wish I could just write my front-end logic in a different language."_  

Our poor developer! Luckily, with modern tools, there are a ways to write more performant front-end code in a language other than Javascript.

### Bring on the WASM
The issues related to Javascript mentioned in the prior section have plagued developers for years. [WebAssembly](http://webassembly.org/) (often referred to as WASM) aims to solve many of them. From the site, WASM is "a portable, size- and load-time-efficient binary format to serve as a compilation target which can be compiled to execute at native speed by taking advantage of common hardware." It is designed to integrate well with the existing Web platform, and will eventually support multithreading. Perhaps most importantly, the initial version of WebAssembly [has reached cross-browser consensus](http://webassembly.org/roadmap/).  

So WebAssembly is a fast, low-level standard. Great! This means it's perfect for building new, higher level languages on. Even better, _**it's a great compilation target for current high-level languages**_. We only need to find a suitable high-level language, and put in the necessary work to get it to compile to WebAssembly.

### Haskell to the rescue
[Haskell](https://www.haskell.org/) is a mature, modern, statically-typed, purely-functional language with a fully-featured type system. As such, it is more conducive to the creation of more composable code that is easier to reason about. Due to its explicit handling of effects, many parts of a Haskell program can be meaningfully parallelized for free; As a matter of fact, the language comes with a "light-weight concurrency library containing a number of useful concurrency primitives and abstractions." As a language, it helps solve many of the _Javascript problems_ that WebAssembly does not directly address.

So Haskell is a fantastic language that is built for handling heavy-duty work and is designed to produce more reasonable code. Awesome. We've got Haskell and we've got WebAssembly. We just need a way to compile Haskell to WebAssembly. That is the goal of the WebGHC project.  
