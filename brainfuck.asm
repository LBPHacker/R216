; * This program makes use of the stack pointer, so it is first initialised to 0
;   and is rarely (never?) written to explicitly.
; * The calling convention used in this program is as follows:
;   * r0 through r9 are saved by the caller,
;   * r10 through r13 are saved by the callee,
;   * arguments are passed and results are returned in caller-saved registers.
; * Sequences of +, -, > and < are collapsed into single commands on the fly
;   after the interpreter sees them at least once.

bootstrap:
    mov sp, 0                 ; * Zero put sp.
    mov r10, 0                ; * terminal should be connected to port 0.
    bump r10                  ; * Reset terminal.
    mov r12, 0x1000           ; * Set cursor position to 0;0.
    send r10, r12
    mov r13, 0xFF             ; * Store address and data mask as a global.
    jmp main

stuff:                        ; * Hello world demo taken from Wikipedia.
    dw "++++++++[>++++[>++>+++>+++>+<<<<"
    dw "-]>+>+>->>+[<]<-]>>.>---.+++++++"
    dw "..+++.>>.<-.<.+++.------.-------"
    dw "-.>>+.>++."
    dw 0                      ; * The code assumes that only valid commands are
                              ;   placed in the code buffer.

main:
    send r10, 0x200F          ; * Set colour to white on black.
    mov r1, stuff             ; * Reset code pointer to the beginning.
    mov r2, 0                 ; * Reset pointer to 0.
    mov r3, 0                 ; * Reset stack to 0.
.loop:
    mov r0, [r1]              ; * Load command.
    jz .code_ended            ; * Exit if we hit the zero terminator.
    js .optimised_code        ; * On-the-fly optimised code has the MSB set.
    cmp r0, '.'               ; * Do some forking here.
    je .op_putchar            ; * Branch off to op_putchar if r0 is a '.'.
    jb .br_sub_getchar_add    ; * Anything below a '.' must be a one of '+,-'.
    cmp r0, '>'               ; * Anything above must be one of '<>[]'.
    je .op_right              ; * Branch off to op_right if r0 is a '>'.
    jb .op_left               ; * Anything below must be a '<' so, so branch
    cmp r0, '['               ;   off to op_left.
    je .op_push               ; * Anything above must be one of '[]'. If it's a
.op_pop:                      ;   '[', branch off to op_push, otherwise
                              ;   stay here in op_pop.
    test r3, r3               ; * Check if we have anything on the stack.
    jz .stack_underflow
    sub r3, 1
    mov r1, [r3+stack]        ; * Jump back to label.
    jmp .loop                 ; * Go again.
.op_push:
    mov r0, [r2+memory]       ; * Check if the cell being pointed at is zero.
    jz .skip_block
    test r3, 0x10             ; * Check if we have space left in the stack.
    jnz .stack_overflow
    mov [r3+stack], r1        ; * Save label address.
    add r3, 1
    add r1, 1                 ; * Advance code pointer.
    jmp .loop                 ; * Go again.
.skip_block:                  ; * We skip the whole block as quickly as
    mov r4, 1                 ;   possible. We record the nesting depth in r4.
.skip_block_loop:
    add r1, 1                 ; * Advance code pointer.
    mov r0, [r1]
    jz .unexpected_eof        ; * Code ended earlier than expected.
    cmp r0, '['               ; * Increment the nesting counter
    je .skip_loop_push        ;   when we find a '['.
    cmp r0, ']'               ; * Decrement the nesting counter
    je .skip_loop_pop         ;   when we find a ']', possibly exiting the loop.
    jmp .skip_block_loop      ; * Skip more commands.
.skip_loop_push:
    add r4, 1                 ; * Increment the nesting counter,
    jmp .skip_block_loop      ;   go again.
.skip_loop_pop:
    sub r4, 1                 ; * Decrement the nesting counter, go again
    jnz .skip_block_loop      ;   if the outermost block hasn't ended yet.
    add r1, 1                 ; * Advance code pointer.
    jmp .loop                 ; * Go again.
.stack_overflow:
    send r10, 0x200C
    send r10, 'O'             ; * Print an 'O' with red on black.
    jmp .done                 ; * Exit.
.stack_underflow:
    send r10, 0x200C
    send r10, 'U'             ; * Print an 'U' with red on black.
    jmp .done                 ; * Exit.
.unexpected_eof:
    send r10, 0x200C
    send r10, 'E'             ; * Print an 'E' with red on black.
    jmp .done                 ; * Exit.
.op_putchar:
    send r10, r12             ; * Send cursor position for safety.
    send r10, [r2+memory]     ; * Send the character stored in the cell being
    add r12, 1                ;   pointed at, then advance cursor.
    add r1, 1                 ; * Advance code pointer.
    jmp .loop                 ; * Go again.
.op_getchar:
    push r3                   ; * Save locals from read_character_blink.
    push r2
    push r4
    mov r6, 0x200F            ; * Read with a white on black cursor.
    mov r11, r12
    call read_character_blink
    pop r4
    pop r2
    mov [r2+memory], r3       ; * Save character read into cell being pointed
    pop r3                    ;   at.
    add r1, 1                 ; * Advance code pointer.
    jmp .loop                 ; * Go again.
.op_add:
    mov r4, [r2+memory]
    mov r5, r1
.op_add_opt:
    add r1, 1                 ; * Advance code pointer.
    cmp [r1], '+'
    je .op_add_opt            ; * Streak optimisation.
    mov r6, r1
    sub r6, r5                ; * Calculate difference.
    add [r2+memory], r6       ; * Add as much to the cell being pointed at as
                              ;   many commands we saw in a streak.
    and [r2+memory], r13      ; * Mask off any excess bits.
    and r6, 0xFF
    or r6, 0x8000             ; * Prefix 0x80..: optimised '+'.
    mov [r5], r6              ; * Save optimised code.
    jmp .loop                 ; * Go again.
.br_sub_getchar_add:
    cmp r0, ','               ; * Do some more forking here.
    je .op_getchar            ; * Branch off to op_getchar if r0 is a ','.
    jb .op_add                ; * Anything below must be a '+', and anything
.op_sub:                      ;   above must be a '-'. Branch or stay
                              ;   accordingly.
    mov r5, r1
.op_sub_opt:
    add r1, 1                 ; * Advance code pointer.
    cmp [r1], '-'
    je .op_sub_opt            ; * Streak optimisation.
    mov r6, r1
    sub r6, r5                ; * Calculate difference.
    sub [r2+memory], r6       ; * Subtract as much from the cell being pointed
                              ;   at as many commands we saw in a streak.
    and [r2+memory], r13      ; * Mask off any excess bits.
    and r6, 0xFF
    or r6, 0x8100             ; * Prefix 0x81..: optimised '-'.
    mov [r5], r6              ; * Save optimised code.
    jmp .loop                 ; * Go again.
.op_right:
    mov r5, r1
.op_right_opt:
    add r1, 1                 ; * Advance code pointer.
    cmp [r1], '>'
    je .op_right_opt          ; * Streak optimisation.
    mov r6, r1
    sub r6, r5                ; * Calculate difference.
    add r2, r6                ; * Subtract as much from the pointer
                              ;   as many commands we saw in a streak.
    and r2, r13               ; * Mask off any excess bits.
    and r6, 0xFF
    or r6, 0x8200             ; * Prefix 0x82..: optimised '>'.
    mov [r5], r6              ; * Save optimised code.
    jmp .loop                 ; * Go again.
.op_left:
    mov r5, r1
.op_left_opt:
    add r1, 1                 ; * Advance code pointer.
    cmp [r1], '<'
    je .op_left_opt           ; * Streak optimisation.
    mov r6, r1
    sub r6, r5                ; * Calculate difference.
    sub r2, r6                ; * Subtract as much from the pointer
                              ;   as many commands we saw in a streak.
    and r2, r13               ; * Mask off any excess bits.
    and r6, 0xFF
    or r6, 0x8300             ; * Prefix 0x83..: optimised '<'.
    mov [r5], r6              ; * Save optimised code.
    jmp .loop                 ; * Go again.
.optimised_code:
    mov r4, r0                ; * Extract optimisation technique index.
    and r0, 0xFF              ; * Extract optimisation parameter.
    shr r4, 8
    and r4, 3
    jmp [r4+.optimised_tbl]   ; * Jump to optimisation technique branch.
.optimised_tbl:
    dw .optimised_op_add
    dw .optimised_op_sub
    dw .optimised_op_right
    dw .optimised_op_left
.optimised_op_add:
    add [r2+memory], r0       ; * Add parameter to cell being pointed at.
    and [r2+memory], r13      ; * Mask off any excess bits.
    add r1, r0                ; * We know we can skip over the next few '+'s.
    jmp .loop                 ; * Go again.
.optimised_op_sub:
    sub [r2+memory], r0       ; * Subtract parameter from cell being pointed at.
    and [r2+memory], r13      ; * Mask off any excess bits.
    add r1, r0                ; * We know we can skip over the next few '-'s.
    jmp .loop                 ; * Go again.
.optimised_op_right:
    add r2, r0                ; * Add parameter to pointer.
    and r2, r13               ; * Mask off any excess bits.
    add r1, r0                ; * We know we can skip over the next few '>'s.
    jmp .loop                 ; * Go again.
.optimised_op_left:
    sub r2, r0                ; * Subtract parameter from pointer.
    and r2, r13               ; * Mask off any excess bits.
    add r1, r0                ; * We know we can skip over the next few '<'s.
    jmp .loop                 ; * Go again.
.code_ended:
    test r3, r3               ; * Check if we have anything on the stack.
    jnz .unexpected_eof       ; * Do unexpected eof dance if there is.
.done:
    hlt
    jmp .done                 ; * Reached the end of the code, die.

memory:                       ; * Tons of memory. 256 cells, to be precise.
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
stack:                       ; * Supports 16 levels of nesting.
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0


; * Reads a single character from the terminal while blinking a cursor.
; * r6 is cursor colour.
; * r10 is terminal port address.
; * r11 is cursor position.
read_character_blink:
    mov r4, 0x7F              ; * r4 holds the current cursor character.
    mov r2, 8                 ; * r2 is the counter for the blink loop.
    send r10, r6
    send r10, r11
    send r10, r4              ; * Display cursor.
.wait_loop:
    wait r3                   ; * Wait for a bump. r3 should be checked but
                              ;   as in this demo there's no other peripheral,
                              ;   it's fine this way.
    jns .got_bump             ; * The sign flag is cleared if a bump arrives.
    sub r2, 1
    jnz .wait_loop            ; * Back to waiting if it's not time to blink yet.
    xor r4, 0x5F              ; * Turn a 0x20 into a 0x7F or vice versa.
    send r10, r6              ;   Those are ' ' and a box, respectively.
    send r10, r11
    send r10, r4              ; * Display cursor.
    mov r2, 8
    jmp .wait_loop            ; * Back to waiting, unconditionally this time.
.got_bump:
    bump r10                  ; * Ask for character code.
.recv_loop:
    recv r3, r10              ; * Receive character code.
    jnc .recv_loop            ; * The carry bit it set if something is received.
    ret
