% R216 Manual and Instruction Reference
% LBPHacker
% 01-06-2022

# R216 Manual and Instruction Reference




## Index

* [Foreword][008]
* [Features in detail][003]
* [Improvements over the R1][001]
* [Improvements to be had over the R2][002]
* [Driving the thing][006]
* [Instruction reference][005]
* [Programming][004]
* [Example programs][007]
* [Notes][009]
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
[009]: #Notes
    "Notes"
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

This computer is none other than the **R2**. The three models that exist right
now are the **R216K2A**, **R216K4A** and the **R216K8B**, of which the R216K2A
features:

* **subframe 16-bit architecture**, but of course;
* **a RAM with 2048 16-bit cells**, which also handles instructions;
* **29-bit instruction set**, meaning instructions fit a single code word;
* **16 16-bit registers**, 14 of which are general purpose ones;
* **shift, add and bitwise operations**, the usual ALU goodness;
* **stack operations**, facilitating simple calls and returns and then some;
* **read-modify-write operations**, increasing throughput when working in RAM;
* **a ton of operand modes**, including a few pretty useless ones;
* **256 virtual I/O ports**, one of which is built in;
* **168×112 particle area**, which is pretty small;
* some leftover magic from the things I usually do.

The three models are mostly identical except for the number of cells in the RAM;
see the table below. These are only the highlights, everything is explained in
detail at some point in the manual. Your best bet is to do some quick Ctrl+F
woodoo if you'd rather not read through all of it.

For the sake of completeness, here's the [R216K2A save page][897], the
[relevant forum thread][898] and a [thing that opens the R216K2A save][896]
directly in TPT if your TPT is configured properly. See a complete list of save
links in the table below. Additionally, all headers are both anchors and links
pointing to themselves, so feel free to copy them around and reference them
anywhere.

|  Model  | RAM size   | Save page    | TPT hotlink   |
| ------- | ---------- | ------------ | ------------- |
| R216K2A | 2048 cells | [https][897] | [ptsave][896] |
| R216K4A | 4096 cells | [https][894] | [ptsave][893] |
| R216K8B | 8192 cells | [https][891] | [ptsave][892] |

While I like to think that my composing skills have improved a lot in the past
few years, mistakes are inevitably made. As always, if you have anything
in mind for this manual, be it a fix or an enhancement or whatever, feel free to
bump me. This manual, among other things, [is on GitHub][899].

[895]: #RAM
    "Features in detail – RAM"
[898]: https://powdertoy.co.uk/Discussions/Thread/View.html?Thread=22833
    "The R216K2A forum thread"
[899]: https://github.com/LBPHacker/R216/blob/master/manual.md
    "R216 Manual and Instruction Reference on GitHub"

[897]: https://powdertoy.co.uk/Browse/View.html?ID=2303519
    "The R216K2A save page"
[894]: https://powdertoy.co.uk/Browse/View.html?ID=2305835
    "The R216K4A save page"
[891]: https://powdertoy.co.uk/Browse/View.html?ID=2342633
    "The R216K8B save page"

[896]: ptsave:2303519#R216K2A
    "Open R216K2A save"
[893]: ptsave:2305835#R216K4A
    "Open R216K4A save"
[892]: ptsave:2342633#R216K8B
    "Open R216K8B save"




## Features in detail

I'll be expanding a bit on the list above. The more seasoned may skip this
section but it's probably worth checking out, at least for the wording if
nothing else.

Several of the subsections here may seem incomplete without the
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
time flows downwards, meaning whatever happens near the top border of the
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
greater width, but of course it's still possible. Bitwise operations provide a
way to extract smaller numbers from the 16-bit cells, while chained operations
provide a way to chain cells together into larger cells, allowing for larger
numbers.

### RAM

The R216K2A model features a magical PSTN-driven 2048-cell FILT RAM
with constant space horizontal and vertical demultiplexers (i.e. it's really
space efficient). Each FILT stores 16 bits of data, except when it stores the 29
bits of an instruction, but as the data path is 16-bit, most of the components
can't access the most significant 13 bits directly. Those are dedicated to the
instruction set and nothing else.

This, weirdly enough, doesn't mean that those bits can't be accessed at all.
They in fact [can be written][573] (but not read), thus allowing for code that
writes code. The R2 has a write-only 13-bit register, the contents of which are
merged with whatever 16-bit value is written to RAM on a direct write.

The R216K4A is very similar to the R216K2A model, except its RAM has 4096 cells.
Likewise, the R216K8B has 8192 cells. I had to fiddle around with it a bit to
squeeze that many cells in, hence the change in the suffix from A to B.

### Instruction set

The R2 instruction set is in an almost perfect balance between width, complexity
and versatility. Using the full 29 bits of the FILT spectrum, it manages to
encode even 16-bit immediate operands in a single cell of RAM if the destination
operand is simple enough. This greatly simplifies the instruction decoder and
saves valuable code space and clock cycles.

Decoder complexity is further reduced by the layout of fields inside the
instructions. 5 bits are dedicated to the operation to be executed on the
operands, 4 bits select an operand mode, and the remaining 20 bits encode
operands, the most important and useful encoding being one that encodes a
register in 4 bits and a 16-bit immediate operand in, unsurprisingly, 16 bits.

### Registers

With a whopping 14 general purpose registers, a stack pointer that's really
almost general purpose beside the fact that stack operations are hardcoded to
use it as the stack pointer (`sp`, which the stock assembler maps to `r14`), and
a read-only instruction pointer (`ip`, which the stock assembler maps to `r15`),
you should be able to avoid hitting memory pretty easily. Any instruction can
use any register without restriction; even the instruction pointer, but that'll
ignore all direct writes.

This allows for simple but efficient calling conventions such as the one I tend
to use, which dedicates the first ten registers to local variables and the next
four to global variables, with locals saved by the caller and globals by the
callee.

### ALU

The ALU includes an adder, a shifter and a bitwise unit, and four flags that
change depending on the outcome of the last ALU instruction, and which
conditional jumps use to decide whether to jump or not.

The adder handles addition and subtraction, both the standalone and the chained
variants. Additions can be chained together to add up numbers whose width
exceeds 16 bits. Flags work the same way with chained additions as with
standalone ones as the outcome of an addition can be fully represented by the
outcome of the last addition in the chain.

The shifter handles left and right shifts and rotation, once again both the
standalone and the chained variants. Much like with addition, shifts can be
chained together to shift big numbers. [With a bit of hacking][580], rotation of
big numbers can be achieved as well. It's important to note that flags do not
work the same way with chained shifts as with standalone ones as the zero flag
reflects the result of only the last shift in the chain. Also note that shifts
_by_ an amount equal to or greater than 16 bits are not supported; chained
shifts by such amounts would act like degenerate cases of `memmove`, which is up
to the user to implement.

The bitwise unit handles basic bitwise operations and copying. Although, once
again, instructions can be chained for big numbers, there's no practical
difference between chained and standalone bitwise instructions. And once again,
with chained instructions the zero flag reflects the result of only the last
instruction, making it impossible to decide if the whole number ended up being
zero or not. This seldom poses a problem though.

### Stack

The R2 has dedicated stack operations that allow pushing to and popping from the
stack, and special variants of these that push the instruction pointer and then
do an unconditional jump (a subroutine call), and that pop a value into the
instruction pointer (a subroutine return). These are hardcoded to use `r14` as
the stack pointer; a push decrements `r14` before writing to the cell
referenced by it and a pop increments `r14` after reading from the cell it
points to.

You can also treat another register as the base pointer (`bp`, which the stock
assembler maps to `r13`) if you're into that kind of stuff. Stack frames
are fun, although in my opinion it doesn't make much sense to dedicate two whole
registers for bookkeeping on such a small, slow and limited architecture.

### Read-modify-write

In the R2 the RAM is sitting at the top. This is because the reading mechanism
requires to be very close to the RAM (unlike the writing mechanism), and because
the R2 is built so whenever an instruction accesses the RAM, a value is both
read and processed in the same frame; likewise, a value is both processed and
written to RAM in the same frame.

This of course means that it's possible to first read a value from RAM, then do
some processing on it, and then even write it back to RAM in the same frame.
This is called a read-modify-write operation and the R2 is perfectly capable of
doing one of these every other frame.

### Operand modes

An operand mode is a certain combination of all kinds of operands for an
instruction to work with. Operands can be registers or cells in the RAM.
Registers are always referred to by their _names_ (an integer between 0 and 15,
inclusive) while RAM cells may be referred to by their addresses. Register names
and addresses can be encoded directly in the instruction. Addresses can also be
calculated on the fly from the contents of registers, in which case the names of
the registers being used are encoded in the instruction instead.

The R216 instruction set has a load of these operand modes. Some allow encoding
16-bit immediate operands, some allow indirect addressing, instructing the
computer to calculate the address by adding or subtracting registers and small
integers. More on this in the [Instruction reference][005].

### I/O ports

The same way the R1 has 4 peripheral ports, the R2 has 256, numbered
from 0 to 255, 0 being the built-in one, all others being virtual in the sense
that while they exist, they cannot be accessed by peripherals without the help
of an _I/O breakout box_. The R2 peripheral interface is hardware-compatible
with the R1 and the few peripherals that exist for the R1 (this does not imply
software-compatibility though, and indeed, most R1-compatible devices that send
data to the computer are impossible to work with, due to reading instructions
being non-blocking).

There are three bundles of FILT exiting the case on the right; one with three
wires, one with one, and one with two. The first two of these constitute the
I/O expansion interface of the R2, to which any number of breakout boxes may be
connected to expose more virtual ports. The third is the traditional 2-wire
peripheral interface, which exposes the built-in port 0 with the help of a
stripped-down version of the breakout box built into the R2.

The breakout boxes provide two 2-wire peripheral interfaces; one on top and
one at the bottom. Note that there are two interfaces for convenience only;
these are not in fact different interfaces and only one of these may be used
with a peripheral at a time.

See also [More on I/O ports][330].

[330]: #More.on.I.O.ports
    "Notes – More on I/O ports"

### Space consumption

With an area of 168×112 particles, the R2 is really quite small. Certainly the
smallest computer _I've ever built_ to date. It could definitely be smaller, as
is apparent by the copious amounts of unused space inside the case. Its width is
dictated by the 128×16 particle RAM, and to some extent its height is too.
I couldn't have it looking weird, so I chose its height so that it looked good
enough with the width I managed to shrink the RAM to, and thus it ended up being
168×112.

In fact that's so much space that I never once had to work on getting components
smaller. Everything just fit perfectly on the first try. And back when I started
building this thing, I was way worse at optimising for space. The
[The CONV tmp trick][390] hadn't been discovered yet either. Oh yeah, I forgot
to mention that this computer has been finished for more than a year, except for
a few bugs I fixed lately and other minor adjustments.

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
general purpose registers. Another one is used as the stack pointer by a few
instructions but it can be used in arithmetic instructions as well. The final
one is the instruction pointer and is read-only, but other than that it works
just like any other register.

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
instructions. Of course this meant that loading a 16-bit immediate into the ALU
was impossible to encode with only a single instruction word. As a result, every
instruction that encoded an immediate other than 0 was encoded in two cells,
which wasted a lot of code space. If this wasn't enough, the instruction
set had a few instructions that would access three registers at a time. In these
ugly cases you would have to choose one of the registers from the first three
GPRs, which is just horrible.

The R2 has none of that madness. It has a 29-bit instruction set, the width of
which is sufficient to encode both 16-bit immediate operands and register names
without compromises. Of course you may come across cases in which the
instruction set can't handle a particular combination of operands, but those
cases are far fewer and far less likely to be annoying than they were in the R1. 

Of course having an instruction set that is wider than the data path means that
writing code to RAM with code is a royal pain.
[Nevertheless it's possible][573], although I don't think it'd cause much of a
problem if it weren't.

### Single chamber RAM

This means that the RAM is one huge block of FILT with a bit of supporting
circuitry, not two or three huge blocks of either FILT or air. In other words,
the FILT count to area ratio of this RAM converges to 1, unlike the RAM in the
R1, the space efficiency ratio of which converges to 2. You get more RAM but it
takes up less space.




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

### Auto-increment indirect operand modes

The idea is that whenever memory is accessed through a register, the value in
the register is incremented after use or decremented before use. There are of
course other options but this is what usually makes the most sense. This could
eliminate the need for dedicated stack instructions (except for `call`) while
providing even more versatile operand modes in general.

Combine this with memory mapped I/O. One word per frame throughput, anyone?

### More sophisticated loop control

There's only so much overhead you can eliminate with loop unrolling. It hurts
to see that the naive implementation of `memcpy` has a throughput of only one
word per six frames or 1:6 on the R2. You can get about 4:10 or more if you can
afford unrolling but that's still not the optimal 1:1 I'd like to have. By
sophisticated loop control I mean zero loop overhead. This is possible, one just
has to be smart about it.

Combine this with auto-increment indirect operand modes. Same question as above.

### Bit finding instructions

Certain algorithms would benefit from instructions that can calculate the index
of the first or last set or unset bit in a word. These instructions may seem
oddly specific, but believe me, at the clock speeds these contraptions run at,
they wouldn't be all that pointless. It's not like it's difficult to build
hardware that supports them either. In fact a few more specific instructions
like these probably wouldn't hurt.

### Better flag support for chained shifts

For a while I thought chaining only made sense in the case of addition and, to
some extent, shifts, so I built the R2 with full flag support for chained
addition and limited flag support for chained shifts. Then I came across a case
in which it would have been really awesome to be able to decide if a 32-bit
number that I just shifted to the left ended up being zero or not, except the
way the shifter in the R2 works didn't allow that. I want something better.

### Shift-and-add engine

This is something that occurred to me while implementing a software FPU for the
R2. The code had so many shift-and-add algorithms and they were so similar
(addition, multiplication, division, square root, CORDIC) that I thought I might
as well build something that can be programmed to run shift-and-add algorithms
quickly. It would likely be a built-in peripheral controlled by memory mapped
I/O instead of a component accessed with a dedicated instruction. It'd make
anything that can be boiled down to a shift-and-add algorithm faster to do.




## Driving the thing

All these features (or the lack thereof) are wonderful, but they're worthless if
you can't turn the thing on. This section is about the few controls the R2 has
and is dedicated to solving this problem.

### No more cartridges

I ditched the cartridge infrastructure the R1 had. Yes, I know, it was fun, but
that was the best that could be said about it. In practice it didn't get too
much attention as you could just copy the R1 around with the cartridge in it. It
was a nice proof of concept and nothing more. You can copy the R2 around with
the program already loaded into RAM.

This unfortunately does mean that programs have to make sure to clean the RAM
before they start doing anything in it as the contents of the cartridge no
longer overwrite everything in the RAM, resetting it to a known good state.
Because there is no cartridge, obviously.

### Start button

For most programs you'll probably only need to use the left button on the front
panel. This is the Start button, which starts the execution of the program
loaded into RAM. A program may decide to stop execution by executing a special
instruction. If you want to resume execution after that, this button can do that
too.

### Reset button

The right button on the front panel is the Reset button, which stops the
execution of the program loaded into RAM and resets the instruction pointer to
zero. It does absolutely nothing else. Pressing this button is the only way to
stop the execution of the program manually. (The program itself can request
to be stopped too.) This means that if you want to examine your program while
it's running, you have to pause the simulation or insert [breakpoints][529]
where you want to break execution and resume execution later with the Start
button.

### Running indicator

The green LCRY indicator on the front panel lights up when the program loaded
into RAM is being executed. There's not much to be said about this, except that
the definition of what is considered a state of execution is simpler in the case
of the R2 than it was in the case of the R1. Unlike in the R1, this indicator
only turns off if execution really has ceased, and not when the core is checking
for [raw data][562] or [an attention request][575] on an I/O port.




## Instruction reference

You can think of instructions as sentences, which have subjects, objects and
verbs. This section defines _operations_ as the verbs and _operands_ as the
objects in these sentences, while the subject is always the computer.
Instructions always have one operation and zero, one or two operands, which are
referred to as _primary_ and _secondary_ operands.

A table with all the operations is provided below for fast navigation. Note
that execution always takes 1 frame longer than specified below if one of the
operands is a memory address. Also note that some of the descriptions of the
conditional jumps may be confusing, for example _jump if not below or equal_.
In these cases, the condition is the exact opposite of the same condition
without the _not_.

Classifying operations by how they take operands yields four different classes,
_no-operand_ (0), _primary-only_ (P), _secondary-only_ (S), and
_primary-and-secondary_ (PS). Operations in different classes are able to handle
different operand modes.

| Mnemonic      | Class | Short description            | Updates flags | Execution time | Code         |
| ------------- | ----- | ---------------------------- | ------------- | -------------- | ------------ |
| [`adc`][520]  | PS    | add with carry               | yes           | 1              | `0x25000000` |
| [`adcs`][520] | PS    | non-storing add with carry   | yes           | 1              | `0x2D000000` |
| [`add`][520]  | PS    | add                          | yes           | 1              | `0x24000000` |
| [`adds`][520] | PS    | non-storing add              | yes           | 1              | `0x2C000000` |
| [`and`][524]  | PS    | bitwise AND                  | yes           | 1              | `0x21000000` |
| [`ands`][524] | PS    | non-storing bitwise AND      | yes           | 1              | `0x29000000` |
| [`bump`][525] | P     | send attention request       |  no           | 1              | `0x38000000` |
| [`call`][526] | S     | call subroutine              |  no           | 2              | `0x3E000000` |
| [`cmb`][527]  | PS    | compare with borrow          | yes           | 1              | `0x2F000000` |
| [`cmp`][527]  | PS    | compare                      | yes           | 1              | `0x2E000000` |
| [`hlt`][529]  | 0     | halt execution               |  no           | 1              | `0x30000000` |
| [`ja`][530]   | S     | jump if above                |  no           | 1              | `0x3100000F` |
| [`jae`][530]  | S     | jump if above or equal       |  no           | 1              | `0x31000003` |
| [`jb`][530]   | S     | jump if below                |  no           | 1              | `0x31000002` |
| [`jbe`][530]  | S     | jump if below or equal       |  no           | 1              | `0x3100000E` |
| [`jc`][530]   | S     | jump if carry set            |  no           | 1              | `0x31000002` |
| [`je`][530]   | S     | jump if equal                |  no           | 1              | `0x31000008` |
| [`jg`][530]   | S     | jump if greater              |  no           | 1              | `0x3100000B` |
| [`jge`][530]  | S     | jump if greater or equal     |  no           | 1              | `0x3100000D` |
| [`jl`][530]   | S     | jump if lower                |  no           | 1              | `0x3100000C` |
| [`jle`][530]  | S     | jump if lower or equal       |  no           | 1              | `0x3100000A` |
| [`jmp`][530]  | S     | jump unconditionally         |  no           | 1              | `0x31000000` |
| [`jn`][530]   | S     | jump never                   |  no           | 1              | `0x31000001` |
| [`jna`][530]  | S     | jump if not above            |  no           | 1              | `0x3100000E` |
| [`jnae`][530] | S     | jump if not above or equal   |  no           | 1              | `0x31000002` |
| [`jnb`][530]  | S     | jump if not below            |  no           | 1              | `0x31000003` |
| [`jnbe`][530] | S     | jump if not below or equal   |  no           | 1              | `0x3100000F` |
| [`jnc`][530]  | S     | jump if carry unset          |  no           | 1              | `0x31000003` |
| [`jne`][530]  | S     | jump if not equal            |  no           | 1              | `0x31000009` |
| [`jng`][530]  | S     | jump if not greater          |  no           | 1              | `0x3100000A` |
| [`jnge`][530] | S     | jump if not greater or equal |  no           | 1              | `0x3100000C` |
| [`jnl`][530]  | S     | jump if not lower            |  no           | 1              | `0x3100000D` |
| [`jnle`][530] | S     | jump if not lower or equal   |  no           | 1              | `0x3100000B` |
| [`jno`][530]  | S     | jump if overflow unset       |  no           | 1              | `0x31000005` |
| [`jns`][530]  | S     | jump if sign unset           |  no           | 1              | `0x31000007` |
| [`jnz`][530]  | S     | jump if not zero             |  no           | 1              | `0x31000009` |
| [`jo`][530]   | S     | jump if overflow set         |  no           | 1              | `0x31000004` |
| [`js`][530]   | S     | jump if sign set             |  no           | 1              | `0x31000006` |
| [`jz`][530]   | S     | jump if zero                 |  no           | 1              | `0x31000008` |
| [`mov`][557]  | PS    | copy value                   | yes           | 1              | `0x20000000` |
| [`nop`][559]  | 0     | do nothing                   |  no           | 1              | `0x31000001` |
| [`or`][558]   | PS    | bitwise OR                   | yes           | 1              | `0x22000000` |
| [`ors`][558]  | PS    | non-storing bitwise OR       | yes           | 1              | `0x2A000000` |
| [`pop`][560]  | P     | pop from stack               | yes           | 2              | `0x3D000000` |
| [`push`][561] | S     | push to stack                | yes           | 2              | `0x3C000000` |
| [`recv`][562] | PS    | check for raw data           | yes           | 1              | `0x3B000000` |
| [`ret`][563]  | 0     | return from subroutine       |  no           | 2              | `0x3F000000` |
| [`rol`][564]  | PS    | rotate left                  | yes           | 1              | `0x32000000` |
| [`ror`][564]  | PS    | rotate right                 | yes           | 1              | `0x33000000` |
| [`sbb`][527]  | PS    | subtract with borrow         | yes           | 1              | `0x27000000` |
| [`sbbs`][527] | PS    | compare with borrow          | yes           | 1              | `0x2F000000` |
| [`send`][567] | PS    | send raw data                |  no           | 1              | `0x3A000000` |
| [`shl`][568]  | PS    | shift left                   | yes           | 1              | `0x34000000` |
| [`scl`][568]  | PS    | chained shift left           | yes           | 1              | `0x36000000` |
| [`shr`][568]  | PS    | shift right                  | yes           | 1              | `0x35000000` |
| [`scr`][568]  | PS    | chained shift right          | yes           | 1              | `0x37000000` |
| [`sub`][527]  | PS    | subtract                     | yes           | 1              | `0x26000000` |
| [`subs`][527] | PS    | compare                      | yes           | 1              | `0x2E000000` |
| [`swm`][573]  | S     | set write mask               | yes           | 1              | `0x28000000` |
| [`test`][524] | PS    | non-storing bitwise AND      | yes           | 1              | `0x29000000` |
| [`wait`][575] | P     | check for attention request  | yes           | 1              | `0x39000000` |
| [`xor`][576]  | PS    | bitwise XOR                  | yes           | 1              | `0x23000000` |
| [`xors`][576] | PS    | non-storing bitwise XOR      | yes           | 1              | `0x2B000000` |

[520]: #ADD..ADC..ADDS..ADCS.--.add
    "Instruction reference – ADD, ADC, ADDS, ADCS – add"
[524]: #AND..TEST.--.bitwise.AND
    "Instruction reference – AND, TEST – bitwise AND"
[525]: #BUMP.--.send.attention.request
    "Instruction reference – BUMP – send attention request"
[526]: #CALL.--.call.subroutine
    "Instruction reference – CALL – call subroutine"
[527]: #SUB..SBB..CMP..CMB.--.subtract.and.compare
    "Instruction reference – SUB, SBB, CMP, CMB – subtract and compare"
[529]: #HLT.--.halt
    "Instruction reference – HLT – halt"
[530]: #JMP..J..--.jump
    "Instruction reference – JMP, J* – jump"
[557]: #MOV.--.copy.value
    "Instruction reference – MOV – copy value"
[559]: #NOP.--.do.nothing
    "Instruction reference – NOP – do nothing"
[558]: #OR..ORS.--.bitwise.OR
    "Instruction reference – OR, ORS – bitwise OR"
[560]: #POP.--.pop.from.stack
    "Instruction reference – POP – pop from stack"
[561]: #PUSH.--.push.to.stack
    "Instruction reference – PUSH – push to stack"
[562]: #RECV.--.check.for.raw.data
    "Instruction reference – RECV – check for raw data"
[563]: #RET.--.return.from.subroutine
    "Instruction reference – RET – return from subroutine"
[564]: #ROL..ROR.--.rotate
    "Instruction reference – ROL, ROR – rotate"
[567]: #SEND.--.send.raw.data
    "Instruction reference – SEND – send raw data"
[568]: #SHL..SHR..SCL..SCR.--.shift
    "Instruction reference – SHL, SHR, SCL, SCR – shift"
[573]: #SWM.--.set.write.mask
    "Instruction reference – SWM – set write mask"
[575]: #WAIT.--.check.for.attention.request
    "Instruction reference – WAIT – check for attention request"
[576]: #XOR..XORS.--.bitwise.XOR
    "Instruction reference – XOR, XORS – bitwise XOR"

Another table with all operand modes is provided below. `OPER` denotes an
operation from the class that matches the one in the second column, `REG`
denotes a register (with a 4-bit name), `U16` a 16-bit unsigned integer, `U11` a
11-bit unsigned integer and `U4` a 4-bit unsigned integer.

| Example                        | Supported by class | Code         | R1 shift | R2 shift | RB shift | I1 shift | I2 shift |
| ------------------------------ | ------------------ | ------------ | -------- | -------- | -------- | -------- | -------- |
| `OPER`                         |                  0 | `0x00000000` |          |          |          |          |          |
| `OPER REG_R1`                  |                  P | `0x00000000` |        0 |          |          |          |          |
| `OPER [REG_R1]`                |                  P | `0x00400000` |        0 |          |          |          |          |
| `OPER [REG_RB+REG_R1]`         |                  P | `0x00C00000` |        0 |          |       16 |          |          |
| `OPER [REG_RB-REG_R1]`         |                  P | `0x00C08000` |        0 |          |       16 |          |          |
| `OPER [U16_I1]`                |                  P | `0x00500000` |          |          |          |        4 |          |
| `OPER [REG_RB+U11_I1]`         |                  P | `0x00D00000` |          |          |       16 |        4 |          |
| `OPER [REG_RB-U11_I1]`         |                  P | `0x00D08000` |          |          |       16 |        4 |          |
| `OPER REG_R2`                  |                  S | `0x00000000` |          |        4 |          |          |          |
| `OPER [REG_R2]`                |                  S | `0x00100000` |          |        4 |          |          |          |
| `OPER [REG_RB+REG_R2]`         |                  S | `0x00900000` |          |        4 |       16 |          |          |
| `OPER [REG_RB-REG_R2]`         |                  S | `0x00908000` |          |        4 |       16 |          |          |
| `OPER U16_I1`                  |                  S | `0x00200000` |          |          |          |        4 |          |
| `OPER [U16_I1]`                |                  S | `0x00300000` |          |          |          |        4 |          |
| `OPER [REG_RB+U11_I1]`         |                  S | `0x00B00000` |          |          |       16 |        4 |          |
| `OPER [REG_RB-U11_I1]`         |                  S | `0x00B08000` |          |          |       16 |        4 |          |
| `OPER REG_R1, REG_R2`          |                 PS | `0x00000000` |        0 |        4 |          |          |          |
| `OPER REG_R1, [REG_R2]`        |                 PS | `0x00100000` |        0 |        4 |          |          |          |
| `OPER REG_R1, [REG_RB+REG_R2]` |                 PS | `0x00900000` |        0 |        4 |       16 |          |          |
| `OPER REG_R1, [REG_RB-REG_R2]` |                 PS | `0x00908000` |        0 |        4 |       16 |          |          |
| `OPER REG_R1, U16_I1`          |                 PS | `0x00200000` |        0 |          |          |        4 |          |
| `OPER REG_R1, [U16_I1]`        |                 PS | `0x00300000` |        0 |          |          |        4 |          |
| `OPER REG_R1, [REG_RB+U11_I1]` |                 PS | `0x00B00000` |        0 |          |       16 |        4 |          |
| `OPER REG_R1, [REG_RB-U11_I1]` |                 PS | `0x00B08000` |        0 |          |       16 |        4 |          |
| `OPER [REG_R1], REG_R2`        |                 PS | `0x00400000` |        0 |        4 |          |          |          |
| `OPER [REG_RB+REG_R1], REG_R2` |                 PS | `0x00C00000` |        0 |        4 |       16 |          |          |
| `OPER [REG_RB-REG_R1], REG_R2` |                 PS | `0x00C08000` |        0 |        4 |       16 |          |          |
| `OPER [U16_I1], REG_R2`        |                 PS | `0x00500000` |          |        0 |          |        4 |          |
| `OPER [REG_RB+U11_I1], REG_R2` |                 PS | `0x00D00000` |          |        0 |       16 |        4 |          |
| `OPER [REG_RB-U11_I1], REG_R2` |                 PS | `0x00D08000` |          |        0 |       16 |        4 |          |
| `OPER [REG_R1], U16_I1`        |                 PS | `0x00600000` |        0 |          |          |        4 |          |
| `OPER [REG_RB+REG_R1], U11_I2` |                 PS | `0x00E00000` |        0 |          |       16 |          |        4 |
| `OPER [REG_RB-REG_R1], U11_I2` |                 PS | `0x00E08000` |        0 |          |       16 |          |        4 |
| `OPER [U16_I1], U4_I2`         |                 PS | `0x00700000` |          |          |          |        4 |        0 |
| `OPER [REG_RB+U11_I1], U4_I2`  |                 PS | `0x00F00000` |          |          |       16 |        4 |        0 |
| `OPER [REG_RB-U11_I1], U4_I2`  |                 PS | `0x00F08000` |          |          |       16 |        4 |        0 |

Feel free to ignore the Code and Shift columns in both tables; you only need
those if you want to get deeper into how [instructions are encoded][501]. Still,
I realise that all those tables look confusing as all heck, so here are a few
examples of different instructions using different operand modes.

[501]: #Instruction.encoding
    "Notes – Instruction encoding"

```r2asm
%include "common"

start:
    mov sp, 0         ; * Zero out sp (1 frame).
    mov r7, .loop     ; * Copy the cell of .loop into r7 (1 frame).
    push 14           ; * Push the integer 14 (2 frames).
.loop:
    shl r4, [r11]     ; * Shift the bits in r4 left by whatever is at the
                      ;   cell pointed to by r11 (2 frames).
    scl r5, [r12]     ; * Chain-shift the bits in r5 left by whatever is at the
                      ;   cell pointed to by r12 (2 frames).
    send [r5-88], r3  ; * Send the value in r3 on the port whose number matches
                      ;   the value at the cell pointed to by r5-88 (2 frames).
    pop [r4+r9]       ; * Pop a value into the cell pointed to by r4+r9
                      ;   (3 frames).
    add r13, [sp]     ; * Add the value on the top of the stack to r13
                      ;   (2 frames).
    hlt               ; * Halt and wait for a resume (1 frame).
    jmp r7            ; * Jump to whatever is stored in r7 (1 frame).
```

Often in this section it's stated that flags are updated according to the
result. How exactly that is done is explained in more detail [here][500].
Flags are _not_ updated when it's not stated explicitly that they are.

[500]: #About.flags
    "Notes – About flags"

### MOV -- copy value

```r2asm
mov primary, secondary ; * Copy value.
```

`mov` simply copies the value from its secondary operand to its primary
operand. Flags are updated according to the value copied.

### AND, TEST -- bitwise AND

```r2asm
and primary, secondary  ; * Bitwise AND.
test primary, secondary ; * Non-storing bitwise AND, also called bit test.
ands primary, secondary ; * Same.
```

`and` does a bitwise AND on the values in its operands and stores the result in
its primary operand. Flags are updated according to this result. `test` is the
non-storing version of `and`, while `ands` is an alias for `test`.

### OR, ORS -- bitwise OR

```r2asm
or primary, secondary  ; * Bitwise OR.
ors primary, secondary ; * Non-storing bitwise OR (uncommon).
```

`or` does a bitwise OR on the values in its operands and stores the result in
its primary operand. Flags are updated according to this result. `ors` is the
(uncommon) non-storing version of `or`.

### XOR, XORS -- bitwise XOR

```r2asm
xor primary, secondary  ; * Bitwise XOR.
xors primary, secondary ; * Non-storing bitwise XOR (uncommon).
```

`xor` does a bitwise XOR on the values in its operands and stores the result in
its primary operand. Flags are updated according to this result. `xors` is the
(uncommon) non-storing version of `xor`.

### ADD, ADC, ADDS, ADCS -- add

```r2asm
add primary, secondary  ; * Add.
adc primary, secondary  ; * Add with carry.
adds primary, secondary ; * Non-storing add (uncommon).
adcs primary, secondary ; * Non-storing add with carry (uncommon).
```

`add` adds the value in its secondary operand to the value in its primary
operand and stores the result in its primary operand. Flags, including carry and
overflow, are updated according to this result. `adc` does the same, except it
adds the carry flag to the result too; the carry flag is worth a 1 if set or a 0
if unset. `adds` and `adcs` are the (uncommon) non-storing versions of `add` and
`adc`, respectively.

These instructions report an unsigned overflow by setting the carry flag and a
signed overflow by setting the overflow flag. These flags are reset otherwise.

### SUB, SBB, CMP, CMB -- subtract and compare

```r2asm
sub primary, secondary  ; * Subtract.
sbb primary, secondary  ; * Subtract with borrow.
cmp primary, secondary  ; * Compare (or non-storing subtract).
subs primary, secondary ; * Same.
cmb primary, secondary  ; * Compare with borrow (uncommon).
sbbs primary, secondary ; * Same.
```

`sub` subtracts the value in its secondary operand from the value in its primary
operand and stores the result in its primary operand. Flags, including carry and
overflow, are updated according to this result. `sbb` does the same, except it
subtracts the carry flag from the result too; the carry flag is worth a 1 if set
or a 0 if unset. `cmp` and `cmb` are the non-storing versions of `sub` and
`sbb`, while `subs` and `sbbs` are aliases for `cmp` and `cmb`, respectively.

These instruction report an unsigned overflow by setting the carry flag and a
signed overflow by setting the overflow flag. These flags are reset otherwise.

### SWM -- set write mask

```r2asm
swm primary ; * Set write mask.
```

`swm` stores the 13 least significant bits of the value in its primary operand
in a write-only 13-bit register, called the _write mask_. When a 16-bit value is
written into RAM, the 13 bits that would otherwise be undefined or empty are
taken from this register. This makes it possible to write to all 29 bits of a
FILT cell, thus also making it possible for code to write code.

By the way, `swm` is the non-storing version of `mov`, which would be so useless
otherwise that it's perfect for a purpose like this. Still, flags are updated
according to the result, which is the value that would be copied.

### HLT -- halt

```r2asm
hlt ; * Halt execution.
```

`hlt` stops execution completely. Unlike sparking the Reset button,
it does not reset the instruction pointer to 0, thus making it ideal for hard
breakpoints. Execution can only be resumed by manually sparking the Start
button.

### JMP, J* -- jump

```r2asm
jmp primary ; * Jump unconditionally.
jnz primary ; * Conditional jump example: jump if not zero.
```

`jmp` unconditionally copies its the value in its primary operand into the
instruction pointer. All other `j*` instructions except `jn` do the same if a
specific condition is met. `jn` literally never does anything (and in fact the
stock assembler maps `nop` to `jn r0`). Jump conditions are combinations of the
states of the carry flag (`Cf`), the overflow flag (`Of`), the zero flag (`Zf`)
and the sign flag (`Sf`). Below is a mapping of such conditions to instruction
mnemonics, including the constant `true` for `jmp` and the constant `false` for
`jn`. See the [huge table][005] for conditions translated to English or
[this page][582] for almost the same mapping.

[582]: http://unixwiz.net/techtips/x86-jumps.html
    "Intel x86 JUMP quick reference"

| Mnemonics           | Condition             |
| ------------------- | --------------------- |
| `jmp`               | `true`                |
| `jn`                | `false`               |
| `jb`, `jnae`, `jc`  | `Cf == 1`             |
| `jnb`, `jae`, `jnc` | `Cf == 0`             |
| `jo`                | `Of == 1`             |
| `jno`               | `Of == 0`             |
| `js`                | `Sf == 1`             |
| `jns`               | `Sf == 0`             |
| `je`, `jz`          | `Zf == 1`             |
| `jne`, `jnz`        | `Zf == 0`             |
| `jle`, `jng`        | `Zf == 1 || Sf != Of` |
| `jnle`, `jg`        | `Zf == 0 && Sf == Of` |
| `jl`, `jnge`        | `Sf != Of`            |
| `jnl`, `jge`        | `Sf == Of`            |
| `jbe`, `jna`        | `Cf == 1 || Zf == 1`  |
| `jnbe`, `ja`        | `Cf == 0 && Zf == 0`  |

### NOP -- do nothing

```r2asm
nop ; * Do nothing.
```

`nop` simply does nothing. Under the hood it's `jn r0`, which is a fun and
useless instruction. You could also use `mov r0, r0` for `nop`, which is the
"blank" instruction whose opcode is `0x20000000`, but that updates flags
according to the value in `r0`, so it does _something_, which is against the
principles of a proper no-operation instruction.

### SHL, SHR, SCL, SCR -- shift

```r2asm
shl primary, secondary ; * Shift left.
shr primary, secondary ; * Shift right.
scl primary, secondary ; * Chained shift left.
scr primary, secondary ; * Chained shift right.
```

`shl` shifts left the bits in its primary operand by an amount taken from the
least significant 4 bits of its secondary operand. `shr` does the same, except
it shifts right. Bits shifted out are discarded, the bits shifted in on the
other side are all zeroes.

`scl` does the same as `shl`, except the bits shifted in are the most
significant bits of the primary operand of the immediately previous shifting
instruction, which usually means a leading `shl` or another `scl`. The relation
between `scr` and `shr` is similar.

Note that having "holes", that is, non-shifting instructions between the
instructions of a long chained shift produces undefined behaviour. Why this
is the case is explained [here][580].

[580]: #Chained.rotations
    "Notes – Chained rotations"

### ROL, ROR -- rotate

```r2asm
rol primary, secondary ; * Rotate left.
ror primary, secondary ; * Rotate right.
```

`rol` rotates left the bits in its primary operand by an amount taken from the
4 least significant bits of its secondary operand. `ror` does the same, except
it rotates right. A rotation is like a [shift][568], but the bits shifted out
are shifted in on the other side.

Chaining rotations is not trivial and involves shifts. This is explained in more
detail [here][580].

### BUMP -- send attention request

```r2asm
bump primary ; * Send attention request.
```

`bump` sets the Attention Request bit for a single frame on the virtual I/O port
whose number matches the value in the primary operand. The Attention Request bit
resets the next frame unless another `bump` that accesses the same port is
executed.

The peripheral on the other end of the port may not detect the attention request
if it's checking the Attention Request bit out of phase with the R2.
[Read this][581] for a solution to this problem.

Due to a hardware bug, specifying a memory address as the primary operand
clobbers the value at that address. If this poses a problem, use a register.
Modern versions of TPTASM don't let you assemble such broken instructions.


[581]: #Asynchronous.I.O.protocol
    "Notes – Asynchronous I/O protocol"

### WAIT -- check for attention request

```r2asm
wait primary ; * Check for attention request.
```

`wait` checks if the Attention Request bit is set on any virtual I/O port. If no
such port exists, `wait` stores -1 (`0xFFFF`) in its primary operand. If such
ports do exist, the number of the one with the highest precedence is stored in
the primary operand. Due to -1 being returned in the first case and the valid
range of port numbers being 0 through 255, the sign flag of the result reflects
whether an attention request was received or not.

The R2 may not detect the attention request if it's checking the Attention
Request bit out of phase with the peripheral on the other end of the port.
[Read this][581] for a solution to this problem.

### SEND -- send raw data

```r2asm
send primary, secondary ; * Send raw data.
```

`send` sets the Raw Data bit for a single frame on the virtual I/O port whose
number matches the primary operand, and redirects the value in the secondary
operand to this port. The Raw Data bit resets and the redirected data disappears
the next frame unless another `send` that accesses the same port and sends the
same raw data is encountered.

The peripheral on the other end of the port may not detect the data sent
if it's checking the Raw Data bit out of phase with the R2.
[Read this][581] for a solution to this problem.

Due to a hardware bug, specifying a memory address as the primary operand
clobbers the value at that address. If this poses a problem, use a register.
Modern versions of TPTASM don't let you assemble such broken instructions.


### RECV -- check for raw data

```r2asm
recv primary, secondary ; * Check for raw data.
```

`recv` checks if the Raw Data bit is set on the virtual I/O port whose number
matches the value in the secondary operand. If it isn't, the carry flag is
cleared. If it is, the carry flag is set and the data visible on the port is
stored in the primary operand. Other flags are updated according to the value
read, or are undefined if no value is read.

The R2 may not detect the raw data being sent if it's checking the Raw Data bit
out of phase with the peripheral on the other end of the port. [Read this][581]
for a solution to this problem.

### PUSH -- push to stack

```r2asm
push primary ; * Push to stack.
```

`push` decrements `sp`, then it writes the value in its primary operand to the
RAM cell pointed to by `sp`. This shows that the stack grows downwards, with
values pushed later stored at lower addresses. Flags are updated according to
the value pushed to the stack.

### POP -- pop from stack

```r2asm
pop primary ; * Pop from stack.
```

`pop` reads a value from the RAM cell pointed to by `sp`, then it increments
`sp` and stores the value read from RAM in its primary operand. This too shows
that the stack grows downwards. Flags are updated according to the value popped
from the stack.

### CALL -- call subroutine

```r2asm
call primary ; * Call subroutine.
```

`call` copies the value in its primary operand into the instruction pointer and
[pushes][561] the address of the instruction immediately following the `call`
itself onto the stack. A later `ret` may pop the value pushed by `call`,
handing execution back to the code after the `call`. In this case, the `call`
is considered a subroutine call. Of course it can be used for all sorts of weird
stuff too, if you're into that.

### RET -- return from subroutine

```r2asm
ret ; * Return from subroutine.
```

`ret` [pops][560] a value from the stack into the instruction pointer. If the
value it pops was pushed by `call` when calling a subroutine, it is considered a
subroutine return. Like `call`, `ret` can also be used for weird stuff.




## Programming

_This section won't teach you assembly._ You'll have to learn that elsewhere,
sorry. It's really fun and worth learning in my opinion. But if you don't know
any, don't give up yet, I still may write a C compiler in Lua for this thing.
You bet I'm crazy enough to do that.

Unless you want to program the thing by hand or write your own assembler, the
first step is to grab [the assembler I made, TPTASM][400] (in fact this might be
a good idea even if you _do_ want to program the thing by hand or want to write
your own assembler; it's pretty well commented). Once you have that, programming
is as simple as chucking your code into a file and issuing

```lua
loadfile("/path/to/tptasm/main.lua")("/path/to/code.asm")
```

in the TPT console (which will get the job done, but it'll be difficult to read
the error and warning messages; read on for a solution).

[400]: https://github.com/LBPHacker/tptasm
    "TPTASM on GitHub"

You may have seen this:

```r2asm
%include "common"

...
```

i.e., the built-in TPTASM header `common` being `%include`d by some of the
examples in this document. This is necessary because TPTASM does a few very
common things, such as implement `dw` or alias `jb` to `jc`, via macros, which
are only available through this header. Using these macros isn't mandatory,
because who am I to tell you what macros to use, right? So the inclusion must
be made optional. That said, using these macros instead of your own is highly
recommended.

TPTASM takes three parameters, the first of which is the path to the source to be
assembled and is mandatory. The second is the (supposedly) unique ID of the CPU
you're trying to program. This is useful if you have more CPUs in the
simulation. The third is the path to a log file to redirect the output of the
assembler to. This is useful if you don't have a utility to show the long output
of the assembler in-game; you can just redirect it to a log file and read that
in any old text editor.

Let's say you want to program the CPU whose identifier is `0xBEEF` (identifiers
are integers and are stored in the ctype property of a FILT particle) and
redirect the output to `tptasm.log`. You'd do this by issuing

```lua
loadfile("/path/to/tptasm/main.lua")("/path/to/code.asm", 0xBEEF, "tptasm.log")
```

If you're wondering how one sets the unique identifier of a CPU, it's as simple
as changing the ctype of the FILT on the left of the one and only QRTZ particle
in the whole contraption (you can find this with Ctrl+F in-game). The stock
model ships with the identifier `0xDEAD`.

Fun fact: this `loadfile` magic is just plain old Lua, so you can load TPTASM
into memory once and then use it later as many times as you want, until you exit
TPT:

```lua
tptasm = loadfile("/path/to/tptasm/main.lua")
tptasm("/path/to/code/for/beef.asm", 0xBEEF, "tptasm.beef.log")
tptasm("/path/to/code/for/dead.asm", 0xDEAD, "tptasm.dead.log")
```



## Example programs

### Quadratic equation solver

The R2 was published with this demo running on it, along with the RT2 terminal,
which this demo uses extensively. It asks for the three
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

[700]: https://github.com/LBPHacker/R216/blob/master/quadratic.asm
    "Quadratic equation solver for the R216 on GitHub"

### Optimising Brainfuck interpreter

A bit less interesting is a traditional Brainfuck interpreter. It collapses
sequences of `+`, `-`, `>` and `<` on the fly. _Hello World!_ example included
in the source.

Source code [available on GitHub][701].

[701]: https://github.com/LBPHacker/R216/blob/master/brainfuck.asm
    "Optimising Brainfuck interpreter for the R216 on GitHub"

### A Forth implementation

What it says on the tin. In case the conditional jumps weren't enough to
convince you of the Turing-completeness of this machine, [siraben][703]'s Forth
implementation definitely will. Forth is a relatively easy-to-port,
stack-oriented language that shows up from time to time as often in the most
unlikely of places as on mainstream computers and emulators. With this, we
finally have the first high-level programming environment in TPT.

Source code [available on GitHub][702].

[702]: https://github.com/siraben/r216-forth/blob/master/forth.asm
    "A Forth implementation for the R216K8B on GitHub"
[703]: https://github.com/siraben
    "siraben's profile on GitHub"




## Notes

This section is a place for all the stuff I couldn't figure out where to dump.
Some subsections here are referenced elsewhere in the manual, some aren't. All
are worth reading.

### About flags

Flags are single bits in the ALU that are updated by certain operations and
the state of which conditional jumps check to decide whether to jump or not.
These flags are the carry flag, the overflow flag, the zero flag and the sign
flag. When an operation is said to update flags, it updates all flags at once.

Operations that update flags are free to go about it however they wish, but
unless specified otherwise, they all follow a common pattern:

* the zero flag is set if the result of the operation is zero, unset otherwise;
* the sign flag is set if the most significant bit of the result of the
  operation is set, unset otherwise;
* the carry flag is set if the operation produces a carry, unset otherwise
  (what producing a carry means depends on the operation);
* the overflow flag is set if the operation results in an overflow, unset
  otherwise (again, what this means depends on the operation).

Operations that don't explicitly state what producing a carry or an overflow
means in their case always reset the carry and overflow flags.

### Instruction encoding

This is a really tedious task of shifting and masking bits, matching patterns
and generally feeling miserable. Assemblers exist for the sole reason of
avoiding having to do this by hand.

We're going to encode `send [r5-88], r3` for demonstration purposes. To encode
an instruction:

* find the operation code corresponding to the operation; in this case
  `send`, which has the code `0x3A000000`;
* find the operand mode that matches the operand list and whose class
  matches the class of the operation; `send` is in class _primary-and-secondary_
  and the operand list matches the `OPER [REG_RB-U11_I1], REG_R2` pattern in
  class _primary-and-secondary_; this operand mode has the code `0x00D08000`;
* substitue the operands into the pattern, convert them to bits and
  shift them to the left by the amount of bits shown next to the pattern in the
  enormous operand mode table;
    * `RB` is `r5` (`0x5`) and is shifted to the left by 16 bits, yielding
      `0x00050000`;
    * `I1` is 88 (`0x58`) and is shifted to the left by 4 bits, yielding
      `0x00000580`;
    * `R2` is `r3` (`0x3`) and is shifted to the left by 0 bits, yielding
      `0x00000003`;
* bitwise OR what you have so far together; this yields `0x3AD58583`, the final
  opcode.

Here's some more example material.

```r2asm
%include "common"

start:
    mov sp, 0         ; * 0x2020000E
    mov r7, .loop     ; * 0x20200037 (assuming .loop = 3)
    push 14           ; * 0x3C2000E0
.loop:
    shl r4, [r11]     ; * 0x341000B4
    scl r5, [r12]     ; * 0x361000C5
    send [r5-88], r3  ; * 0x3AD58583
    pop [r4+r9]       ; * 0x3DC40009
    add r13, [sp]     ; * 0x241000ED
    hlt               ; * 0x30000000
    jmp r7            ; * 0x31000070
```

There exist opcodes that are not documented. For example, you'd never get the
opcode `0x200DED01` from the above calculation, even though it's a perfectly
valid opcode (it's in fact `mov r1, r0`, just like `0x20000001` is). This is
because operand modes may not define the purpose of some bits in the opcode, and
as such it's up to the user (or an assembler) to decide whether to make those
bits zeroes or ones. The tables in this manual are crafted so that these
undefined bits are always zeroed out.

So once the R2 recognises an operand mode, it knows which bits to ignore. These
bits have no effect on the operation and may be chosen to be zeroes or ones
arbitrarily. That leaves the question of undefined operand modes. Those with
keener eyes may notice that operand modes `0x00800000` and `0x00A00000` are
missing from the operand mode table. This doesn't mean that they are undefined,
they are just not documented and in fact they behave exactly like modes
`0x00000000` and `0x00200000`, respectively. In other words, there are no
undefined operand modes. This means that the R2 should be able to handle
whatever combination of 29 bits you throw at it.

### Chained rotations

Chained shifts are simple. A left shift you can simply start off with an `shl`
and continue with a bunch of `scl`s, like this:

```r2asm
shl r4, 9 ; * Shift r4_64 to the left by 9 bits.
scl r5, 9
scl r6, 9
scl r7, 9
```

Chained rotations (for example rotating `r4_64` left by 9 bits so that the 9
bits that are rotated out of `r7` are rotated back into `r4`) are a bit
trickier. In fact the R2 provides no hardware support for this, so we have to be
smart about it.

The shifter in the R2 implements chained shifts by saving the value of the
primary operand of the last instruction executed. This means that an `scl` has
access to all the bits of the primary operand of a previous shifting instruction
(and, really, any instruction; this is why chained shifts with holes are not
supported and yield unexpected results). `scl` and friends simply shift these
bits in the other direction and merge them with whatever they get as their
primary operands.

We can abuse this to implement a chained rotation like this:

```r2asm
shl r7, 0 ; * Get r7 into the internal register of the shifter. The register
          ;   isn't affected by how far the value is shifted, but the primary
          ;   operand is, so we shift here by 0.
scl r4, 9 ; * The bits from r7 are magically shifted into r4.
scl r5, 9
scl r6, 9
scl r7, 9
```

That's it. It's one instruction more than you would expect but it's not bad. For
the record, the same can be done to rotate right:

```r2asm
shr r4, 0
scr r7, 9
scr r6, 9
scr r5, 9
scr r4, 9
```

### More on I/O ports

I/O breakout boxes can be configured to expose any of the 256 virtual ports of
the R2 by setting the ctype of a FILT particle in them to `0x1??00000`, where
`??` is the number of the port to be exposed, in the range between 0 and 255.
The FILT particle can be identified by its temperature: it's around 4000C and
shows up yellow in heat view. The same applies to the stripped-down version of
the breakout box built into the R2, which exposes port 0; the ctype of the FILT
particle in that is `0x10000000` (and changing it is not recommended).

As stated before, any number of breakout boxes may be connected to the
expansion interface; in other words, breakout boxes are stackable. The
built-in breakout box and all external breakout boxes are collectively referred
to as the _I/O bus_. Exposing the same port with multiple breakout boxes on the
same bus leads to undefined behaviour.

There's a fundamental difference between how the R1 and the R2 handle
peripherals: the R1 blocks while waiting for [raw data][562] or an
[attention request][575] (in fact it almost completely turns off) while the
R2 simply sets flags depending on the result of checking for either of those
two for a single frame. More on this in the [Instruction reference][005].

When multiple attention requests are present on the bus, the one closest to the
R2 takes precedence. For example, an attention request on the built-in port 0
takes precedence over any other attention request on the bus, and a
check for an attention request succeeds with a result of 0 in this case.
There's no precedence defined between incoming raw data as ports are addressed
explicitly when data is received.

### Asynchronous I/O protocol

The fact that the R2 doesn't block when checking for attention requests or
raw data on a port might be scary at first, but everything can be done with
non-blocking instructions too. In fact, the thing that should give you the most
trouble is synchronising up the computer and the peripheral (which may be
another computer). This section won't tell you how to solve every problem
arising from not having blocking port reading instructions, but it should
give you a general idea.

So the problem is that if you use `wait` to wait for an attention request, the
tightest loop you can have is a 2-cycle one. Okay, let's go with that:

```r2asm
    ...
.loop:
    wait r0  ; * Try again if we got -1. If we didn't, the port requiring
    js .loop ;   attention is in r0.
    bump r0  ; * Send a bump back to notify the peripheral that we're listening.
    ...
```

The problem with that is that if the peripheral sends only one attention
request, we might miss that. The solution is to make the peripheral send two.
No, I'm not kidding. Just send one right after the first. In fact it's better to
just make the peripheral send attention requests until it gets one back
(a bump).

So that's one mystery solved. But let's say the peripheral starts sending a
stream of raw data right after it gets a bump back. How do we know when it
starts streaming exactly? We could wait for another bump, but if the peripheral
sends only one, we might miss it. If it sends two, how do we know which one we
got? And we do have to know which one we got, otherwise we're not synchronised.

The solution is to have the peripheral send two easily differentiable pieces of
dummy raw data. I recommend sending `0x0000` and then `0x8000`, because then we
can do a `js` right after the `jnc` needed to detect that we got some data.

```r2asm
    ...
.bump_loop:
    wait r0         ; * Try again if we got -1. If we didn't, the port requiring
    js .bump_loop   ;   attention is in r0.
    bump r0         ; * Send a bump back to notify the peripheral that we're
                    ;   listening.
.sync_loop:
    recv r1, r0     ; * Wait for the dummy pieces of data.
    jnc .sync_loop
    js .skip_nop
    nop             ; * We caught the 0x0000, let's waste one cycle.
.skip_nop:
    nop             ; * Insert a few more nops if you like, it doesn't really
    nop             ;   matter, we're synchronised now and the stream can start.
    ...
```

That's it. If that doesn't clear everything up, bump me and I'll try to extend
this section to cover more ground. I think it should be about enough to get you
started with synchronisation though.

### I/O protocol on-the-wire format details

An R2 I/O port is a bidirectional data channel, which in practice means that
it's two lines of FILT with changing ctypes. In the case of a horizontal pair of
lines of FILT, the one on top forwards data to the right, while the bottom one
to the left. A vertical pair is just the same thing rotated by 90 degrees, so
the right one forwards data downwards, the left one upwards.

Ultimately, the only FILT particle whose ctype matters is the one that the
receiver shoots BRAY through or otherwise reads. This is however very cumbersome
to control directly, both for complexity and documentation reasons, so for
convenience, it's recommended to set the ctype of the entire FILT line.

The keepalive bit is 0x20000000, this is always set in both lines of FILT in
both directions. When the port is idle in a direction, no other bit is set in
in the corresponding line of FILT. An attention request is signalled by the
0x10000 bit being set, while raw data is signalled by the 0x20000 bit being set,
along with the 16 least significant bits set to the data being sent.

### The terminal

The terminal peripheral present in the [R2 showcase save][896], the RT2, has a
simple protocol that has long eluded documentation, due to how little required
it seemed. This section is dedicated to this protocol.

The screen part of the terminal only supports 16-colour text mode, which
essentially means plotting characters onto the cells of a grid. The size of
the grid is 16×12 in the RT2812A model, which is currently also the only
existing model. Plotting in this case refers to drawing a 6×6 sprite with a
depth of a single bit, which translates to a choice between two colours,
the foreground colour and the background colour.

The keyboard part of the terminal is just a peripheral that, once a key is
pressed, sends attention requests until it gets one back, at which point it
eventually sends the character code corresponding to the key [twice][581]. Until
this happens, it doesn't accept more input (its buffer can only hold one key). A
common pattern is clearing this buffer by sending the keyboard an attention
request before starting an input routine.

The screen and keyboard parts of the terminal may be used independently of each
other.

Plotting is achieved by sending the terminal a character to plot. The colours
used for plotting are 4-bit [CGA colours][901] and are stored in an internal
8-bit colour register.

[901]: https://en.wikipedia.org/wiki/Color_Graphics_Adapter#Color_palette
	"CGA colour palette"

The terminal also has an internal 10-bit cursor register, the four least
significant bits of which determine which column a character is plotted in,
and the rest of the bits of which determine which row. Invalid column-row
combinations result in no character being plotted. Regardless, this register
is incremented every time an attempt is made to plot a character.

Commands are sent to the terminal as raw data using [`send`][567]. It
differentiates between three kinds of commands:

 - `0x00??`, which plots the character corresponding to `??`;
 - `0x1???`, which sets the internal cursor register to `???` (the two most
   significant bits are discarded);
 - `0x20??`, which sets the internal colour register to `??` (high nibble
   selects background colour, low nibble selects foreground colour).

The 25 bits that encode the top-left 5×5 pixels of the 6×6 sprite are taken from
a 256-character ROM; a set bit represents the foreground colour, an unset one
the background colour. The rest of the 6×6 sprite is hardcoded to use the
background colour. Below is the mapping of bits to sprite pixels, with the
crosses representing the hardcoded region, and an example of the sprite for `2`,
which is stored as `0x212AE640` in the ROM (bit 29 is the keep-alive bit).

```
+--+--+--+--+--+--+   +--+--+--+--+--+--+
| 0| 5|10|15|20| -|   |  |  |##|##|  |  |
| 1| 6|11|16|21| -|   |  |##|  |  |##|  |
| 2| 7|12|17|22| -|   |  |  |  |##|  |  |
| 3| 8|13|18|23| -|   |  |  |##|  |  |  |
| 4| 9|14|19|24| -|   |  |##|##|##|##|  |
| -| -| -| -| -| -|   |  |  |  |  |  |  |
+--+--+--+--+--+--+   +--+--+--+--+--+--+
```

The character set encoded in the ROM of the RT2812A model is
[available here](font.png). The first 8 rows conform to 7-bit ASCII, as far as
printable characters go.




## Changelog

* 07-07-2018: Initial release
* 18-07-2018: Typo and wording fixes
* 26-10-2018: Add R216K8B to the list of models
* 28-11-2019: Link siraben's Forth
* 04-10-2020: Document RT2812A protocol
* 01-06-2022: Document `bump`/`send` memory primary operand bug
* 18-11-2024: Document I/O port on-the-wire format

