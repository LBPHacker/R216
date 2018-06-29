% R2 Manual
% LBPHacker
% 29-06-2018

# Manual and Instruction Reference for R216K2A




## Index

* [Foreword][008]
* [Features in detail][003]
* [Improvements over the R1][001]
* [Improvements to be had over the R2][002]
* [Driving the thing][006]
* [Instruction reference][005]
* [Programming][004]
* [Example programs][007]
* [Changelog][099]

[008]: #Foreword
	"Foreword"
[001]: #Improvements.over.the.R1
	"Improvements over the R1"
[002]: #Improvements.to.be.had.over.the.R2
	"Improvements to be had over the R2"
[099]: #Changelog
	"Changelog"
[003]: #Features.in.detail
	"Features in detail"
[004]: #Programming
	"Programming"
[005]: #Instruction.reference
	"Instruction reference"
[006]: #Driving.the.thing
	"Driving the thing"
[007]: #Example.programs
	"Example programs"




## Foreword

It's been more than two years since I published the [**R16K1S60**][800] (**R1** 
for short). By the time I got to the point where I had a working assembler and a
manual and all that sort of stuff that's not nearly as fun to work on as the
computer itself, I realised that it had several crippling limitations. And yes,
by that time I already had another computer in mind that would solve at least a
few of those limitations.

[800]: /powdertoy/R16K1S60/manual.md
	"Manual and Instruction Reference for R16K1S60"

This computer is none other than the **R2**. At the time of publishing the only
existing model is the **R216K2A**, which features:

* **subframe 16-bit architecture**, but of course;
* **29-bit instruction set**, meaning instruction fit a single cell;
* **a RAM with 2048 16-bit cells**, which also handles 29-bit instructions;
* **16 16-bit registers**, 14 of which are general purpose ones;
* **shift, add and bitwise operations**, the usual ALU goodness;
* **stack operations**, facilitating simple calls and returns and then some;
* **read-modify-write operations**, increasing throughput when working in RAM;
* **a ton of operand modes**, including a few pretty useless ones;
* **256 virtual I/O ports**, one of which is built in;
* **168×112 particle area**, which is pretty small;
* some leftover magic from the things I usually do.

These are only the highlights, everything is explained in detail at some point
in the manual. Your best bet is to do some quick Ctrl+F woodoo if you'd rather
not read through all of it.

A random fact that I'll probably forget to mention anywhere else is that I built
the R2 so that it's easy to upgrade the RAM to a 4096-cell one, so if anyone
is interested in seeing an **R216K4A**, you know where to knock.

For the sake of completeness, here's the [R216K2A save page][897], the
[relevant forum thread][898] and a [thing that opens the R216K2A save][896]
directly in TPT if your TPT is configured proper.y

While I like to think that my composing skills have improved a lot in the past
few years, mistakes are inevitably made. As always, if you have anything
in mind for this manual, be it a fix or an enhancement or whatever, feel free to
bump me. This manual, among other things, [is on GitHub][899].

[896]: #
	"Open R216K2A save (BROKEN)"
[897]: #
	"The R216K2A save page (BROKEN)"
[898]: #
	"The R216K2A forum thread (BROKEN)"
[899]: https://github.com/LBPHacker/R216
	"R216 GitHub repository"




## Features in detail

I'll be expanding a bit on the list above. The more seasoned may skip this
section but it's probably worth checking out, at least for the wording if
nothing else.

Several of the sections here may seem incomplete without the
[Instruction reference][005]. In fact I appended that link to so many of the
sections at first that I ended up moving it up here instead.

### Subframe

With the power of high sorcery (and reading TPT's source), man has created
subframe technology, of which the R2 is a rather heavy piece. It exploits the
way TPT handles particles to make fast data processing possible. Except for the
column of missing FILT running around in the RAM, the R2 may appear completely
stationary to the outside viewer, although the fact that with decorations off
the contraption turns into a huge blob of colourful flashy FILT may give
away that there's a lot more going on than that.

The meaning of time changes completely as the R2 executes often more than a
hundred small operations in a single frame, seemingly in no time at all. To an
extent, time appears in the space the components of the R2 occupy, since in TPT
time flows downward, meaning whatever happens near the top border of the
simulation happens earlier than whatever happens near the bottom border. You can
tell that a component is complex by its size rather than by the time it takes to
produce a result.

This is of course a terrible introduction to subframe and there are
[much better ones][300] out there. [Heck, even I made one][301].

[300]: http://powdertoy.co.uk/Discussions/Thread/View.html?Thread=22405
	"The Subframe Lessons by mark2222"
[301]: http://powdertoy.co.uk/Browse/View.html?ID=2028385
	"A few words on subframe by LBPHacker"

### Data path

It's 16 bits, meaning you get the highest theoretical throughput when working
with numbers of that size. It's a pain to work with numbers of both smaller and
greater width, but of course it's still possible. Logical instructions provide a
way to extract smaller numbers from the 16-bit cells, while continuation
instructions provide a way to chain cells together into larger cells, allowing
for larger numbers.

### Instruction set

Lol.

### RAM

Lol.

### Registers

Lol.

### ALU

Lol.

### Stack

Lol.

### Read-modify-write

Lol.

### Operand modes

Lol.

### I/O ports

Lol.

### Space consumption

With an area of 168×112 particles, the R2 is really quite small. Certainly the
smallest computer _I've ever built_ to date. It could definitely be smaller, as
is apparent by the huge amount of unused space inside the case. Its width is
dictated by the 128×16 particle RAM, and to some extent also its height. I can't
have it looking weird, can I? So I chose a height that looked good enough with
the width I managed to shrink the RAM to, and thus it ended up being 168×112.

In fact that's so much space that I never once had to work on getting components
smaller. Everything just fit perfectly on the first try. And back when I started
building this thing, I was way worse at optimising for space. The
[The CONV tmp trick][390] hasn't been discovered yet either. Oh yeah, I forgot
to mention that this computer has been finished for more than a year, except for
a bug I fixed last month.

[390]: http://powdertoy.co.uk/Browse/View.html?ID=2143540
	"CONV is awesome by LBPHacker"




## Improvements over the R1

_Or the things I like about it._ Yes, I've had this list compiled since about
the time I published the R1. That seems to be how this works; you build
something and the imperfections bug you.

### More registers

This is the most obvious one. While writing programs for the R1, I couldn't help
but notice that 5 general purpose registers are barely enough for anything. I
guess this is something you sort of expect when you build a computer with only a
handful of general purpose registers, but actually dealing with the problem is
different.

So this is how I dealt with this problem; I added more registers. The R2 has 14
general purpose registers. The 15th one is used as the stack pointer by a few
instructions but it can be used in arithmetic instructions as well. The 16th is
the instruction pointer and is read-only, but other than that it works just like
any other register.

### Memory access for everyone

Second in importance probably only to the number of registers, this feature
makes it possible to access memory with every instruction. There's no longer a
separate instruction used to access memory, like in the R1, which in my
opinion was the worst design decision in the whole thing. That approach works
well for simple embedded systems or fast RISC processors running at extremely
high clock speeds, but it doesn't work so well in a simulator where you're
limited to a sub-200 frequency range.

### Read-modify-write operations

This is something I've wanted to have in the R1 too, but then I got lazy and I
ended up scrapping the idea. This means that the R2 is able to read a value from
RAM, do some processing on it, and then write the result back into RAM in a
single instruction. And all that in the same amount of time it'd take to do a
standalone read or a standalone write.

### 29-bit instruction set

The R1 had this problem that its instruction set used 16-bit words to encode
instructions. Of course this meant that Loading a 16-bit immediate into the ALU
was impossible to encode with only a single instruction word. As a result every
instruction that encoded an immediate other than 0 was encoded in two cells,
which wasted a lot of code space. If this wasn't enough, the instruction set had
a few instructions that would access three registers at a time. In these ugly
cases you would have to choose one of the registers from the first three GPRs,
which is just horrible.

The R2 has none of that madness. It's a pure RISC with a 29-bit instruction set,
the width of which is sufficient to encode both 16-bit immediate operands and
register names without compromises. Of course you may come across cases when the
instruction set can't handle a particular combination of operands, but those
cases are far fewer and far less likely to be annoying than they were in the R1. 

Of course having an instruction set that is wider than writing code to RAM with
using other code is is a royal pain. [Nevertheless it's possible][110], although
I don't think it'd cause much of a problem if it weren't.

[110]: #
	"SWM instruction (BROKEN)"




## Improvements to be had over the R2

_Or the things I'd like to have in it._ Everything I said in the previous
section applies here as well, except this time it's the things the R2 doesn't
have rather than things it does have. And yes, this does mean that the rise of
an **R3** is quite possible and even likely in the future.

### Single-frame memory access

This would greatly reduce the importance of registers and
would demote them from being the primary site for processing to the status of
pointers to whatever is being processed. I would very much like to see this
happen. This should be even easier to achieve than before with the appearance of
new particles in TPT and new subframe techniques.

### Memory mapped I/O

Having instructions dedicated to I/O wastes valuable instruction space and
requires additional decoding logic. A solution to this is exposing the control
and data lines of the RAM to peripherals, both built-in and external. These
would check if regions assigned to them were being accessed and would handle
data coming from the core on writes and would send data back on reads.

The way I imagine this stretches the boundaries of simple memory mapped I/O and
sounds a bit like DMA.

### Autoincrement indirect operand modes

The idea is that whenever memory is accessed through a register, the value in
the register is incremented after use or decremented before use. There are of
course other options but this us what usually makes the most sense. This could
eliminate the need for dedicated stack instructions (except for `call`) while
providing even more versatile operand modes in general.

Combine this with memory mapped I/O. One word per frame throughput, anyone?

### More sophisticated loop control

There's only so much overhead you can eliminate with loop unrolling. It hurts
to see that the naive implementation of `memcpy` has a throughput of only one
word per six frames or 1/6 on the R2. You can get about 4/10 or more if you can
afford unrolling but that's still not the optimal 1/2 I'd like to have. By
sophisticated loop control I mean zero loop overhead. This is possible, one just
has to be smart about it.

Combine this with autoincrement indirect operand modes. Same question as above.

### Bit finding instructions

Certain algorithms would benefit from instructions that can calculate the index
of the first or last set or unset bit in a word. These instructions may seem
oddly specific, but believe me, at the clock speeds these contraptions run at,
they wouldn't be all that pointless. It's not like it's difficult to build
hardware that supports them either. In fact a few more specific instructions
like these probably wouldn't hurt.

### Shift-and-add engine

This is something that occurred to me while implementing a software FPU for the
R2. The code had so many shift-and-add algorithms and they were so similar
(addition, multiplication, division, square root, CORDIC) that I thought I might
as well build something that can be programmed to run shift-and-add algorithms
quickly. It would likely be a built-in peripheral controlled by memory mapped
I/O instead of a component accessed with a dedicated instruction. It'd make
anything that can be boiled down to a shift-and-add algorithm faster to do.




## Driving the thing

### No more cartridges

I ditched the cartridge infrastructure the R1 had. Yes, I know, it was fun, but
that was the best that could be said about it. In practice it didn't get too
much attention as you could just copy the R1 around with the cartridge in it. It
was a nice proof of concept and nothing more. You can copy the R2 around with
the program already loaded into RAM.

This unfortunately does mean that programs have to make sure to clean the RAM
before they start doing anything in it as the contents of the cartridge no
longer overwrites everything in the RAM, resetting it to a known good state.
Because there is no cartridge, obviously.

### Start button

For most programs you'll probably only need to use the left button on the front
panel. This is the Start button, which starts or resumes the execution of the
program loaded into RAM.

### Reset button

There right button on the front panel is the Reset button, which stops the
execution of the program loaded into RAM and resets the instruction pointer to
zero. It does absolutely nothing else. Pressing this button is the only way to
stop the execution of the program manually. (The program itself can request
to be stopped too.)

This means that if you want to examine your program while it's running, you have
to pause the simulation or insert [breakpoints][210] where you want to break
execution and resume execution later with the Start button.

### Running indicator

The green LCRY indicator on the front panel lights up when the program loaded
into RAM is being executed. There's not much to be said about this, except that
the definition of what is considered a state of execution is simpler in the case
or the R2 than it was in the case of the R1. Unlike in the R1, this indicator
only turns off if execution really has ceased, and not when the core is waiting
for [a message][211] or [an acknowledgement][212] on an I/O port.

[210]: #
	"HLT instruction (BROKEN)"
[211]: #
	"RECV instruction (BROKEN)"
[212]: #
	"WAIT instruction (BROKEN)"




## Instruction reference

Lol.





## Programming

Lol.




## Example programs

Okay, I lied when I said there would be _programs_. There's only one right now.

### Quadratic equation solver

The R2 was published with this demo running on it, along with the T2 terminal
and the K2 keyboard, which this demo uses extensively. It asks for the three
real coefficients of a quadratic equation and outputs its solutions. It also
handles the single real solution and the double complex solution cases. It even
shows a tiny progress bar while working on the solutions so you won't feel like
you're being ignored.

Under the hood it implements a very incomplete but quite passable imitation of
the IEEE 754 floating point environment. Everything is done using the single
precision format. Subnormals are not supported and rounding may be a bit off
here and there. Of the standard operations, only addition, subtraction,
multiplication, division and square root are implemented, which is just enough
to solve quadratic equations.

Source code [available on GitHub][700].

[700]: #
	"Quadratic equation solver (BROKEN)"




## Changelog

* 29-06-2018: Initial release

