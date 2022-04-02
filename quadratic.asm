; * This is the source code for the program used in
;   https://powdertoy.co.uk/Browse/View.html?ID=2303519

; * This program makes use of the stack pointer, so it is first initialised to 0
;   and is rarely (never?) written to explicitly.
; * The calling convention used in this program is as follows:
;   * r0 through r9 are saved by the caller,
;   * r10 through r13 are saved by the callee,
;   * arguments are passed and results are returned in caller-saved registers.
; * Denormals are not supported right now, and I'm not sure how difficult it'd
;   be to add support. Probably very difficult so I pass.
;
; * Some comments only make sense if you realise that this code was written by a
;   living, breathing person. Yes, I'm one, however difficult that may be to
;   believe.
;
;           -- LBPHacker


%include "common"


; * Entry point.
; * It's nothing special, it's not like the assembler looks for it or anything,
;   it's just what's at address 0 so it's the entry point.
; * I wasn't even alive back when this was the norm.
start:
    mov sp, 0                 ; * Initialise stack pointer.
    mov r10, 0                ; * r10 holds the address of the port
                              ;   the terminal is connected to.
    bump r10                  ; * Reset terminal.
    send r10, 0x1012
    mov r0, .string_formula
    call write_string         ; * Print formula for fun.
.demo:
    mov r12, .inputdata_prompt
.inputdata_loop:
    mov r0, r12
    call write_string         ; * Print prompts, one for each of A, B and C.
    mov r0, 14
    call clear_continuous     ; * Clear previous input.
    mov r0, global_str_buf
    mov r1, 14
    mov r7, 0x200F
    mov r11, [r12]
    add r11, 2
    call read_string          ; * Read string.
    mov r0, global_str_buf
    call float_from_string    ; * Convert to float.
    test r1, r1
    jnz .inputdata_loop       ; * Try again if the conversion failed.
    push r3                   ; * Push number to stack.
    push r2
    add r12, 6
    test [r12], 0xFFFF
    jnz .inputdata_loop       ; * Exit loop if there are no more prompts left.
                              ; * At this point the stack is ($, A, B, C) (where
                              ;   $ is the bottom of the stack in this context).
    send r10, 0x2080
    send r10, 0x1072
    mov r0, .working_string
    call write_string         ; * Draw empty progress bar.
    mov r13, 0x1072           ; * Prepare for bumping the progress bar
    mov r12, .working_string  ;   continuously throughout the calculation.
    mov r0, [sp+4]            ; * Move A into r0_32.
    mov r1, [sp+5]
    mov r2, r1                ; * Check if A is 0, ...
    and r2, 0x7FFF
    or r2, r0
    jz .demo_emit_linear      ;   ... branch off if it is.
    pop r2                    ; * Pop C, stack is ($, A, B).
    pop r3
    call float_multiply       ; * Multiply A and C, yielding AC.
    call .bump_progress_bar
    mov r2, 0x0000            ; * This is 4.0.
    mov r3, 0x4080
    call float_multiply       ; * Multiply AC and 4.0, yielding 4AC.
    push r1
    push r0                   ; * Push 4AC back, stack is ($, A, B, 4AC).
    call .bump_progress_bar
    mov r0, [sp+4]            ; * Move A into r0_32.
    mov r1, [sp+5]
    mov r2, 0x0000            ; * This is 2.0.
    mov r3, 0x4000
    call float_multiply       ; * Multiply A and 2.0, yielding 2A.
    mov [sp+4], r0
    mov [sp+5], r1            ; * Write 2A back, stack is ($, 2A, B, 4AC).
    call .bump_progress_bar
    mov r0, [sp+2]            ; * Move B into r0_32.
    mov r1, [sp+3]
    mov r2, 0x8000
    xor [sp+3], r2            ; * The old B on the stack becomes -B. Stack is
    mov r2, r0                ;   ($, 2A, -B, 4AC).
    mov r3, r1                ; * Copy B into r2_32.
    call float_multiply       ; * Multiply B with itself, yielding B**2.
    call .bump_progress_bar
    pop r2
    pop r3                    ; * Pop 4AC into r2_32, stack is ($, 2A, -B).
    call float_subtract       ; * Subtract 4AC from B**2, yielding B**2-4AC.
    call .bump_progress_bar
    mov r2, r1                ; * Check if B**2-4AC is 0, ...
    and r2, 0x7FFF
    or r2, r0
    jz .demo_emit_single      ;   ... branch off if it is.
    test r1, 0x8000           ; * Check if B**2-4AC is negative,
    jnz .demo_emit_complex    ;   branch off if it is.
    call float_sqrt
    push r1                   ; * Calculate sqrt(B**2-4AC) and push it onto the
    push r0                   ;   stack, stack is ($, 2A, -B, sqrt(B**2-4AC)).
    call .bump_progress_bar
    mov r0, [sp+2]            ; * Move -B into r0_32.
    mov r1, [sp+3]
    mov r2, [sp+0]            ; * Move sqrt(B**2-4AC) into r2_32.
    mov r3, [sp+1]
    call float_subtract       ; * Subtract sqrt(B**2-4AC) from -B, push the
    push r1                   ;   result back, stack is ($, 2A,
    push r0                   ;   -B, sqrt(B**2-4AC), -B-sqrt(B**2-4AC)).
    call .bump_progress_bar
    mov r0, [sp+4]            ; * Move -B into r0_32.
    mov r1, [sp+5]
    mov r2, [sp+2]            ; * Move sqrt(B**2-4AC) into r2_32.
    mov r3, [sp+3]
    call float_add            ; * Add sqrt(B**2-4AC) to -B, update the old -B on
    mov [sp+4], r0            ;   the stack, stack is ($, 2A, -B+sqrt(B**2-4AC), 
    mov [sp+5], r1            ;   sqrt(B**2-4AC), -B-sqrt(B**2-4AC)).
    call .bump_progress_bar
    mov r2, [sp+6]            ; * Move 2A into r2_32.
    mov r3, [sp+7]
    pop r0                    ; * Pop -B-sqrt(B**2-4AC) into r0_32, stack is
    pop r1                    ;   ($, 2A, -B+sqrt(B**2-4AC), sqrt(B**2-4AC)).
    call float_divide         ; * Divide...
    call .bump_progress_bar
    mov r2, r0
    mov r3, r1
    mov r0, global_str_buf
    call float_to_string      ;   ... and then convert,...
    send r10, 0x1090
    mov r0, .string_x1
    call write_string         ;   ... then tell the user what we're printing,...
    mov r0, 13
    call clear_continuous     ;   ... then clear the previous solution...
    send r10, 0x1093
    mov r0, global_str_buf
    call write_string         ;   ... and print the current solution.
    call .bump_progress_bar
    mov r0, [sp+2]            ; * Move -B+sqrt(B**2-4AC) into r0_32.
    mov r1, [sp+3]
    mov r2, [sp+4]            ; * Move 2A into r2_32.
    mov r3, [sp+5]
    call float_divide         ; * Divide...
    call .bump_progress_bar
    mov r2, r0
    mov r3, r1
    mov r0, global_str_buf
    call float_to_string      ;   ... and then convert,...
    send r10, 0x10A0
    mov r0, .string_x2
    call write_string         ;   ... then tell the user what we're printing,...
    mov r0, 13
    call clear_continuous     ;   ... then clear the previous solution...
    send r10, 0x10A3
    mov r0, global_str_buf
    call write_string         ;   ... and print the current solution.
    call .bump_progress_bar
    add sp, 6                 ; * Pop everything, stack is ($).
    jmp .demo_wrapup          ; * Then branch off.
.demo_emit_complex:
    call .bump_progress_bar   ; * We can skip a few steps here.
    call .bump_progress_bar   ; * Reminder: stack is ($, 2A, -B).
    xor r1, 0x8000            ; * r0_32 is B**2-4AC, and it's negative. Make
    call float_sqrt           ;   it positive and take the square root.
    push r1
    push r0                   ; * Push it back,
    call .bump_progress_bar   ;   stack is ($, 2A, -B, sqrt(B**2-4AC)).
    mov r0, [sp+2]            ; * Move -B into r0_32.
    mov r1, [sp+3]
    mov r2, [sp+4]            ; * Move 2A into r0_32.
    mov r3, [sp+5]
    call float_divide         ; * Divide -B by 2A, yielding -B/2A, the real part
    call .bump_progress_bar   ;   of both solutions.
    mov r2, r0
    mov r3, r1
    mov r0, global_str_buf
    call float_to_string      ; * And then convert,...
    send r10, 0x1090
    mov r0, .string_xc
    call write_string         ;   ... then tell the user what we're printing,...
    mov r0, 14
    call clear_continuous     ;   ... then clear the previous solution...
    send r10, 0x1092
    mov r0, global_str_buf
    call write_string         ;   ... and print the current solution.
    call .bump_progress_bar
    pop r0                    ; * Pop sqrt(B**2-4AC) into r0_32,
    pop r1                    ;   stack is ($, 2A, -B).
    mov r2, [sp+2]            ; * Move 2A into r2_32.
    mov r3, [sp+3]
    call float_divide         ; * Divide...
    call .bump_progress_bar
    mov r2, r0
    mov r3, r1
    mov r0, global_str_buf
    call float_to_string      ;   ... and then convert,...
    send r10, 0x10A0
    mov r0, .string_xpm
    call write_string         ;   ... then tell the user what we're printing,...
    mov r0, 14
    call clear_continuous     ;   ... then clear the previous solution...
    send r10, 0x10A2
    mov r0, global_str_buf
    call write_string         ;   ... and print both current solutions
    send r10, 'i'             ;   with an i for the imaginary parts.
    call .bump_progress_bar
    add sp, 4                 ; * Pop everything, stack is ($).
    jmp .demo_wrapup          ; * Then branch off.
.demo_emit_linear:
    call .bump_progress_bar   ; * We can skip a few steps here.
    call .bump_progress_bar
    call .bump_progress_bar
    call .bump_progress_bar
    call .bump_progress_bar
    call .bump_progress_bar
    call .bump_progress_bar
    call .bump_progress_bar
    call .bump_progress_bar
    call .bump_progress_bar   ; * Reminder: stack is ($, A, B, C).
    pop r0
    pop r1                    ; * Pop C into r0_32, stack is ($, A, B).
    pop r2
    pop r3                    ; * Pop B into r2_32, stack is ($, A).
    mov r4, r3                ; * Check if B is 0, ...
    and r4, 0x7FFF
    or r4, r2
    jz .demo_emit_constant    ;   ... branch off if it is.
    xor r3, 0x8000            ; * Negate B, yielding -B.
    call float_divide         ; * Divide...
    call .bump_progress_bar
    mov r2, r0
    mov r3, r1
    mov r0, global_str_buf
    call float_to_string      ;   ... and then convert,...
    send r10, 0x1090
    mov r0, .string_xc
    call write_string         ;   ... then tell the user what we're printing,...
    mov r0, 14
    call clear_continuous     ;   ... then clear the previous solution...
    send r10, 0x1092
    mov r0, global_str_buf
    call write_string         ;   ... and print both current solutions.
    send r10, 0x10A0
    mov r0, .string_xl
    call write_string         ; * State that this is the linear equation case.
    call .bump_progress_bar
    add sp, 2                 ; * Pop everything, stack is ($).
    jmp .demo_wrapup          ; * Then branch off.
.demo_emit_constant:
    call .bump_progress_bar
    mov r4, r1                ; * Prepare to state that this is the no solution
    and r4, 0x7FFF            ;   case, but then check if C is 0, ...
    or r4, r0
    jz .demo_emit_zeroes      ;   ... and make it the all-zeroes case
    mov r0, .string_xn        ;   only if it is.
    jmp .demo_emit_zeroes_or_none
.demo_emit_zeroes:
    mov r0, .string_xz
.demo_emit_zeroes_or_none:
    send r10, 0x1090
    call write_string         ; * State that this is the no solution case.
    send r10, 0x10A0
    mov r0, 16
    call clear_continuous     ; * Clear the previous solution.
    call .bump_progress_bar   ; * Reminder: stack is ($, A).
    add sp, 2                 ; * Pop everything, stack is ($).
    jmp .demo_wrapup          ; * Then branch off.
.demo_emit_single:
    call .bump_progress_bar   ; * We can skip a few steps here.
    call .bump_progress_bar
    call .bump_progress_bar
    call .bump_progress_bar
    call .bump_progress_bar   ; * Reminder: stack is ($, 2A, -B).
    pop r0
    pop r1                    ; * Pop -B into r0_32, stack is ($, 2A).
    pop r2
    pop r3                    ; * Pop 2A into r2_32, stack is ($).
    call float_divide         ; * Divide...
    call .bump_progress_bar
    mov r2, r0
    mov r3, r1
    mov r0, global_str_buf
    call float_to_string      ;   ... and then convert,...
    send r10, 0x1090
    mov r0, .string_xc
    call write_string         ;   ... then tell the user what we're printing,...
    mov r0, 14
    call clear_continuous     ;   ... then clear the previous solution...
    send r10, 0x1092
    mov r0, global_str_buf
    call write_string         ;   ... and print both current solutions.
    send r10, 0x10A0
    mov r0, .string_xs
    call write_string         ; * State that this is the single solution case.
    call .bump_progress_bar
.demo_wrapup:
    send r10, 0x2003
    send r10, 0x1071
    mov r0, .press_any_key_string
    call write_string         ; * Display nice Press any key message.
    bump r10                  ; * Drop whatever is in the input buffer.
    mov r6, 0x2003
    mov r11, 0x107E
    call read_character_blink ; * Wait for a key press while blinking.
    send r10, 0x2000
    send r10, 0x1071
    mov r0, .press_any_key_string
    call write_string         ; * Clear Press any key message.
    send r10, 32
    jmp .demo                 ; * Start over.
.bump_progress_bar:
    send r10, 0x20F0
    send r10, r13             ; * r13 remembers the position of the last
    add r13, 1                ;   character written to the progress bar.
    send r10, [r12]           ; * r12 remembers the pointer to the last
    add r12, 1                ;   character written to the progress bar.
    ret
.string_formula:
    dw 0x200C, "A", 0x200F, "X**2+"
    dw 0x200E, "B", 0x200F, "X+"
    dw 0x200A, "C", 0x200F, "=0", 0
.inputdata_prompt:
    dw 0x1030, 0x200C, "A", 0x200F, "=", 0
    dw 0x1040, 0x200E, "B", 0x200F, "=", 0
    dw 0x1050, 0x200A, "C", 0x200F, "=", 0
    dw 0
.string_x1:
    dw 0x200F, "X1=", 0
.string_x2:
    dw 0x200F, "X2=", 0
.string_xc:
    dw 0x200F, "X=", 0
.string_xpm:
    dw 0x200F, " ", 0xB5, 0
.string_xs:
    dw 0x2007, "  (double root) ", 0
.string_xn:
    dw 0x2007, "  (no solution) ", 0
.string_xz:
    dw 0x2007, "  (zeroes case) ", 0
.string_xl:
    dw 0x2007, "  (linear case) ", 0
.working_string:
    dw " Hold on... ", 0
.press_any_key_string:
    dw "Press any key", 0




global_str_buf:
    dw "              "       ; * Global string buffer for use with functions
                              ;   that operate on strings. 14 cells. Don't
                              ;   worry, it's thread-safe.




; * Reads a single character from the terminal.
; * Character code is returned in r0.
; * r10 is terminal port address.
read_character:
.wait_loop:
    wait r3                   ; * Wait for a bump. r3 should be checked but
                              ;   as in this demo there's no other peripheral,
                              ;   it's fine this way.
    js .wait_loop
    bump r10                  ; * Ask for character code.
.recv_loop:
    recv r0, r10              ; * Receive character code.
    jnc .recv_loop            ; * The carry bit it set if something is received.
    ret




; * Sends spaces to the terminal.
; * r10 holds the number of spaces to send.
clear_continuous:
.loop:
    send r10, 32
    sub r0, 1
    jnz .loop
    ret



; * Reads a single character from the terminal while blinking a cursor.
; * r6 is cursor colour.
; * r10 is terminal port address.
; * r11 is cursor position.
; * Character read is returned in r3.
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




; * Reads zero-terminated strings from the terminal.
; * r0 points to buffer to read into and r1 is the size of the buffer,
;   including the zero that terminates the string. If you have a 15 cell
;   buffer, do pass 15 in r1, but expect only 14 characters to be read at most.
; * r7 is the default cursor colour (the one used when the buffer is not about
;   to overflow; when it is, the cursor changes to yellow, 0x200E).
; * r10 is terminal port address.
; * r11 is cursor position.
read_string:
    bump r10                  ; * Drop whatever is in the input buffer.
    mov r5, r1
    sub r5, 1                 ; * The size of the buffer includes the
                              ;   terminating zero, so the character limit
                              ;   should be one less than this size.
    mov r6, r7                ; * Reset the default cursor colour.
    mov r1, 0                 ; * r1 holds the number of characters read.
.read_character:
    call read_character_blink
    cmp r3, 13                ; * Check for thr Return key.
    je .got_return
    cmp r3, 8                 ; * Check for the Backspace key.
    je .got_backspace
    cmp r5, r1                ; * Check if whatever else we got fits the buffer.
    je .read_character
    send r10, r11             ; * If it does, display it and add it to the
    send r10, r3              ;   buffer.
    add r11, 1
    mov [r0+r1], r3
    add r1, 1
    cmp r5, r1
    ja .read_character        ; * Change cursor colour to yellow if the buffer
    mov r6, 0x200E            ;   is full.
    jmp .read_character       ; * Back to waiting.
.got_backspace:
    cmp r1, 0                 ; * Only delete a character if there is at least
    je .read_character        ;   one to delete.
    mov r6, r7                ; * Reset the default cursor colour.
    send r10, r11
    send r10, 0x20            ; * Clear the previous position of the cursor.
    sub r11, 1
    sub r1, 1
    jmp .read_character       ; * Back to waiting.
.got_return:
    send r10, r11
    send r10, 0x20            ; * Clear the previous position of the cursor.
    mov [r0+r1], 0            ; * Terminate string explicitly.
    ret




; * Writes zero-terminated strings to the terminal.
; * r0 points to buffer to write from.
; * r10 is terminal port address.
; * r11 is incremented by the number of characters sent to the terminal (which
;   doesn't help at all if the string contains colour or cursor codes).
write_string:
    mov r2, r0
.loop:
    mov r1, [r0]
    jz .exit
    add r0, 1
    send r10, r1
    jmp .loop
.exit:
    add r11, r0
    sub r11, r2
    ret




; * Parses a floating point number from a zero-terminated string.
; * r0 points to the string buffer.
; * r1 is 0 if the conversion succeeds or 1 if it fails.
;   * NOTE: Proper nan and inf input should be implemented eventually, which
;           should override default success detection (i.e. the conversion may
;           actually succeed even though the result is nan).
; * r2_32 is the result of the conversion or nan if the conversion fails.
; * Requires a working stack.
float_from_string:
    mov r2, 0                 ; * r2_32 holds the digits read. In other
    mov r3, 0                 ;   words, it's the digit buffer.
    mov r4, 0                 ; * r4 holds the number of digits read. Its upper
                              ;   8 bits hold the number of digits in the
                              ;   explicit exponent.
    mov r5, 0                 ; * r5 holds the relative base-10 exponent of the
                              ;   number entered. The number entered is
                              ;   basically r2_32 * (10 ** r5), e.g. for
                              ;   3.141592 r2_32 would be 3141592 and r5 would
                              ;   be -6 after parsing.
    mov r8, 0                 ; * r8 holds the parser state:
                              ;   * bit 0: parsed explicit base-10 exponent,
                              ;   * bit 1: sign of explicit base-10 exponent,
                              ;   * bit 2: leading zeroes have been ignored,
                              ;   * bit 15: sign of the number.
    mov r9, 1                 ; * r9 is 1 until the decimal dot is read and
                              ;   becomes 0 afterwards. It's used to increment
                              ;   r5 for every digit read.
.ignore_spaces:
    cmp [r0], ' '
    jne .parse_sign
    add r0, 1                 ; * Ignore leading spaces.
    jmp .ignore_spaces
.parse_sign:
    cmp [r0], '+'
    je .sign_positive
    cmp [r0], '-'
    jne .ignore_zeroes
    xor r8, 0x8000            ; * Flip the sign of the number.
.sign_positive:
    add r0, 1
.ignore_zeroes:
    cmp [r0], '0'
    jne .parse_digits
    or r8, 0x0004
    add r0, 1                 ; * Ignore leading zeroes.
    jmp .ignore_zeroes
.parse_digits:
    mov r1, [r0]
    sub r1, '0'
    jnz .no_2nd_ignore_zeroes ; * It's possible that we get this far even though
                              ;   there are still leading zeroes to be ignored.
                              ; * The reason might be a dot that breaks the
                              ;   first streak of zeroes. If this is the case,
                              ;   continue skipping zeroes here.
    ors r9, r4                ; * The ors here clears the zero flag if either
    jnz .no_3rd_ignore_zeroes ;   the dot hasn't been read yet or if all the
                              ;   leading zeroes have been skipped, derived from
                              ;   the fact that r4 is more than 0.
    sub r5, 1                 ; * Decrement r5 if the dot has already been read.
    add r0, 1                 ; * The trick is that we don't increase r4, the
    jmp .parse_digits         ;   significant digit counter.
.no_2nd_ignore_zeroes:
    jb .parse_dot             ; * It's not a digit but it may still be a dot.
.no_3rd_ignore_zeroes:        ; * We may arrive to this label after the ors
                              ;   check above. This branch skips the jb above
                              ;   because it'd act based on the flags we get
                              ;   from the ors.
    cmp r1, 9                 ; * That's a '9' (we subtracted 0x30 earlier).
    ja .parse_dot             ; * It's not a digit but it may still be a dot.
    cmp r4, 7                 ; * The parser only guarantees a precision of
    ja .ignore_last_digit     ;   7 digits, any more than that is truncated.
    je .truncate_last_digit
    mov r6, r2                ; * Multiply r2_32 by 10.
    mov r7, r3                ; * Basically the following happens:
    shl r6, 2                 ;   * r6_32 = r2_32,
    scl r7, 2                 ;   * r6_32 <<= 2,
    add r2, r6                ;   * r2_32 += r6_32,
    adc r3, r7                ;   * r2_32 <<= 1.
    shl r2, 1                 ; * So in the end (r2_32 * (4 + 1)) * 2 or
    scl r3, 1                 ;   r2_32 * 10 is assigned to r2_32.
    add r2, r1                ; * Add r1 to r2_32, merging in the last digit.
    adc r3, 0
    sub r5, 1                 ; * Decrement r5 if the dot has already been read.
    add r5, r9
    jmp .back_to_digit_loop
.truncate_last_digit:
    cmp r1, 5                 ; * At this point the digit cannot be merged
    jb .ignore_last_digit     ;   into the buffer but it can help make whatever
    add r2, 1                 ;   is in the buffer a closer approximation of
    adc r3, 0                 ;   the number entered.
.ignore_last_digit:
    add r5, r9                ; * This is a bit tricky. Increment r5 if the
                              ;   dot hasn't been read yet. This is needed
                              ;   because even though the digit read is ignored,
                              ;   it still does influence the base-10 exponent
                              ;   of the number if it's not after the decimal
                              ;   dot.
.back_to_digit_loop:
    add r4, 1                 ; * Increment digit counter.
    add r0, 1
    jmp .parse_digits
.parse_dot:
    cmp r1, 0xFFFE            ; * That's a '.' (we subtracted 0x30 earlier,
                              ;   0xFFFE = -2).
    jne .parse_exponent       ; * If it's not a even dot, move on.
    test r9, r9               ; * Check if the dot has already been read.
    jz .parse_exponent        ;   Move on if it has.
    mov r9, 0                 ; * Well, it certainly has now.
    add r0, 1
    jmp .parse_digits
.parse_exponent:
    mov r9, 0                 ; * r9 will hold the explicit base-10 exponent.
    cmp [r0], 'e'
    je .seen_exponent_e
    cmp [r0], 'E'
    jne .parse_done
.seen_exponent_e:
    xor r8, 0x0001            ; * Flip explicit exponent bit in parser state.
    add r0, 1
    cmp [r0], '+'
    je .sign_exponent_positive
    cmp [r0], '-'
    jne .read_exp_digits
    xor r8, 0x0002            ; * Flip exponent sign bit in parser state.
.sign_exponent_positive:
    add r0, 1
.read_exp_digits:
    mov r1, [r0]
    sub r1, '0'
    jb .read_exp_done         ; * It's not a digit, move on.
    cmp r1, 9                 ; * That's a '9' (we subtracted 0x30 earlier).
    ja .read_exp_done         ; * It's not a digit, move on.
    add r0, 1
    mov r7, r9                ; * The same thing happens here as earlier,
    shl r7, 2                 ;   except it's 16-bit arithmetic now and it's
    add r9, r7                ;   much easier to follow:
    shl r9, 1                 ;   * r9 = (r9 * (4 + 1)) * 2.
    add r9, r1                ; * Merge digit into buffer.
    add r4, 0x100             ; * Increment digit counter for the exponent.
    jmp .read_exp_digits
.read_exp_done:
    mov r1, r8                ; * Load final sign into r1 for the early return
    and r1, 0x8000            ;   code paths.
    cmp r9, 38                ; * In case of an overflow this may not jump, but
    ja .huge_exponent         ;   the later check of the number of digits in the
    test r8, 0x0002           ;   exponent will. Otherwise it works fine.
    jz .no_negate_exp
    xor r9, 0xFFFF            ; * Trick to negate r9 if the exponent had a
    add r9, 1                 ;   negative sign.
.no_negate_exp:
.parse_done:
    mov r1, r8                ; * Load final sign into r1 for the early return
    and r1, 0x8000            ;   code paths.
    mov r6, r8
    and r6, 0x0004
    add r4, r6                ; * Merge leading zero bit into r4.
    test r4, 0xFF             ; * No digits, not a valid result.
    jz .result_is_nan
    test r8, 0x0001           ; * Skip checking the explicit exponent if it
    jz .no_check_exponent     ;   doesn't exist.
    test r4, 0xFF00           ; * No digits, not a valid result.
    jz .result_is_nan
    cmp r4, 0x0300            ; * Too many digits in the exponent.
    jae .huge_exponent
.no_check_exponent:
    add r9, r5                ; * Merge base-10 exponent with the relative
                              ;   base-10 exponent from earlier.
    mov r4, 158               ; * r4 will hold the base-2 logarithm of the
    test r3, r3               ;   number. The bias would originally be 127 but
    jnz .no_shift16_dbuffer   ;   since our 32-bit digit buffer is not yet
    mov r3, r2                ;   normalised, another bias of 31 is added.
    mov r2, 0
    sub r4, 16
    test r3, r3               ; * If there's nothing in the digit buffer, there
    jz .result_is_zero        ;   is no point in trying to shift anything.
.no_shift16_dbuffer:          ; * The conditional shift above and the loop here
    mov r5, 0xFF00            ;   normalise the digit buffer. The goal is to
    mov r7, 8                 ;   shift it until the MSB is set.
.shift_dbuffer_loop:
    test r3, r5
    jnz .shift_dbuffer_skip
    sub r4, r7                ; * This shifting of course affects the base-2
    shl r2, r7                ;   logarithm.
    scl r3, r7
.shift_dbuffer_skip:
    shr r7, 1
    jz .shift_dbuffer_done
    shl r5, r7
    jmp .shift_dbuffer_loop
.shift_dbuffer_done:
    mov r6, 0x4D42            ; * Load log10(2) << 32 into r6_32.
    mov r7, 0x4D10
    and r8, 0x8000            ; * Only preserve the parser state from r8
    push r8                   ;   and push it.
    mov r8, 0                 ; * Load r9 << 25 into r8_32.
    shl r9, 9                 ; * This is going to get technical.
    jns .no_mult_2_128        ; * If the base-10 exponent is negative, quickly
    sub r4, 128               ;   divide the digit buffer by 2 ** 128 (through
    add r8, r6                ;   the base-2 logarithm). Of course this means
    adc r9, r7                ;   the base-10 exponent has to be increased by
.no_mult_2_128:               ;   log10(2 ** 128).
    shr r7, 1
    scr r6, 1                 ; * r6_32 is now log10(2) << 31.
    test r9, r9
    jns .no_mult_2_64         ; * If the base-10 exponent is negative, quickly
    sub r4, 64                ;   divide the digit buffer by 2 ** 64 (through
    add r8, r6                ;   the base-2 logarithm). Of course this means
    adc r9, r7                ;   the base-10 exponent has to be increased by
.no_mult_2_64:                ;   log10(2 ** 64).
    push r11                  ; * Incredibly, we're going to need to use these
    push r10                  ;   registers as locals.
    mov r5, 0x40              ; * Loop with 7 iterations (loop condition
.cordic_coarse_loop:          ;   is jnz).
    mov r10, r8               ; * Bring the base-10 exponent as close to
    mov r11, r9               ;   log10(3/2) as possible as that's the value
    sub r8, r6                ;   we can reliably reduce to 0 with the finer
    sbb r9, r7                ;   CORDIC loop that uses an actual lookup table.
    jc .ccl_restore_r8_32
    add r4, r5
    jmp .ccl_success
.ccl_restore_r8_32:
    mov r8, r10
    mov r9, r11
.ccl_success:
    shr r7, 1
    scr r6, 1
    shr r5, 1
    jnz .cordic_coarse_loop
    shl r8, 7                 ; * The base-10 exponent is now quite reduced,
    scl r9, 7                 ;   shifting it up gives us more precision.
    push r0
    mov r0, 30                ; * Loop with 31 iterations (loop condition
.cordic_fine_loop:            ;   is jnc).
    mov r10, r8               ; * CORDIC time. Subtract entries in the lookup
    mov r11, r9               ;   table from the base-10 exponent and increment
    sub r8, [r0+.cordic_table_low]
    sbb r9, [r0+.cordic_table_high]
    jc .cfl_restore_r8_32     ;   the base-2 logarithm if the subtraction yields
    mov r1, 31                ;   a positive result.
    sub r1, r0                ; * The constants in the lookup table are
    mov r10, r2               ;   log10(1 + 2 ** (-n)) where n is in the range
    mov r11, r3               ;   [31, 1]. 1 + 2 ** (-n) is easily doable with
    test r1, 0x10             ;   shifts and adds and that's what happens here.
    jz .cfl_no_shift16
    mov r10, r11
    mov r11, 0
.cfl_no_shift16:
    shr r11, r1               ; * r10_32 is shifted down n bits.
    scr r10, r1
    add r2, r10               ; * And with this r2_32 is multiplied by (roughly)
    adc r3, r11               ;   1 + 2 ** (-n).
    jnc .cfl_success
    shr r3, 1
    scr r2, 1
    or r3, 0x8000             ; * Restore lost bit and increment base-2
    add r4, 1                 ;   logarithm if the addition yields a carry.
    jmp .cfl_success
.cfl_restore_r8_32:
    mov r8, r10
    mov r9, r11
.cfl_success:
    shl r8, 1
    scl r9, 1
    sub r0, 1
    jnc .cordic_fine_loop
    shr r3, 8                 ; * Shift digit buffer down by 8.
    scr r2, 8
    pop r0                    ; * Pop stuff saved earlier.
    pop r10
    pop r11
    pop r1                    ; * r1 now holds the sign bit of the result.
    cmp r4, 0
    jl .result_is_zero
    cmp r4, 254
    jg .result_is_inf
    and r3, 0x7F              ; * Pack into IEEE-754 single precision format.
    shl r4, 7
    or r3, r4
    mov r4, 0
.encode_and_exit:
    xor r3, r1                ; * Merge sign bit.
    mov r1, r4
    ret
.result_is_nan:
    mov r3, 0x7FFF
    mov r2, 0xFFFF
    mov r4, 1
    jmp .encode_and_exit
.result_is_inf:
    mov r3, 0x7F80
    mov r2, 0x0000
    mov r4, 0
    jmp .encode_and_exit
.result_is_zero:
    mov r3, 0x0000
    mov r2, 0x0000
    mov r4, 0
    jmp .encode_and_exit
.huge_exponent:
    test r8, 0x0002           ; * A huge explicit exponent means inf if it's
    jz .result_is_inf         ;   positive, zero if it's negative.
    jmp .result_is_zero
.cordic_table_low:
    dw 0xF62A, 0xF629, 0xF629, 0xF628 ; * Low words of log10(1 + 2 ** (-n))
    dw 0xF626, 0xF623, 0xF61C, 0xF60E ;   values with the MSB being
    dw 0xF5F2, 0xF5BB, 0xF54B, 0xF46D ;   2 ** (-32 - n), n ranging from
    dw 0xF2B0, 0xEF37, 0xE844, 0xDA5E ;   31 to 1.
    dw 0xBE93, 0x86FD, 0x17D3, 0x3985
    dw 0x7D05, 0x0473, 0x150C, 0x3D29
    dw 0xA8E4, 0xED49, 0x211D, 0xF256
    dw 0x53AC, 0x3071, 0x5116
.cordic_table_high:
    dw 0x3796, 0x3796, 0x3796, 0x3796 ; * High words of log10(1 + 2 ** (-n))
    dw 0x3796, 0x3796, 0x3796, 0x3796 ;   values with the MSB being
    dw 0x3796, 0x3796, 0x3796, 0x3796 ;   2 ** (-32 - n), n ranging from
    dw 0x3796, 0x3796, 0x3796, 0x3796 ;   31 to 1.
    dw 0x3796, 0x3796, 0x3796, 0x3795 ; * I desperately want to reduce the size
    dw 0x3793, 0x3790, 0x3789, 0x377B ;   of this table. Literally more than
    dw 0x375F, 0x3728, 0x36BD, 0x35EB ;   half of it is just 0x3796. Any ideas?
    dw 0x3461, 0x319E, 0x2D14




; * Renders a floating point number as a zero-terminated string.
; * r0 points to the string buffer.
; * r1 is the number of characters written, including the trailing zero.
; * r2_32 is the number to be converted.
; * Requires a working stack.
float_to_string:
    push r0                   ; * Save string buffer pointer.
    test r3, r3               ; * Check sign bit.
    jns .sign_positive
    mov [r0], '-'
    add r0, 1
.sign_positive:
    mov r1, r3                ; * Extract base-2 exponent into r1.
    shr r1, 7
    and r1, 0xFF
    jz .result_is_zero        ; * Handle special cases early on.
    cmp r1, 255
    je .result_is_inf
    sub r1, 127               ; * Remove bias.
    and r3, 0x007F            ; * Extract mantissa into r2_32.
    or r3, 0x0080
    push r3                   ; * Save these for later. We really do need these
    push r2                   ;   registers for the coarse loop.

    mov r2, 0                 ; * We store 0 in r2_48, which is going to hold
    mov r3, 0                 ;   the base-10 logarithm.
    mov r4, 0
    mov r5, 0x7DE8            ; * We store 0x4D104D427DE8 in r5_48, which is
    mov r6, 0x4D42            ;   log10(2) << 48. Yes, we're going to use
    mov r7, 0x4D10            ;   48-bit arithmetic. Fun stuff.
    test r1, r1
    jns .base2_log_nonnegative
    sub r2, r5                ; * This way we only have to deal with positive
    sbb r3, r6                ;   base-2 exponents.
    sbb r4, r7
    add r1, 128
.base2_log_nonnegative:
    mov r8, 0x40              ; * The coarse loop iterates 7 times. See exit
.coarse_loop:                 ;   condition later.
    shr r7, 1                 ; * This loop basically gives an upper estimate of
    scr r6, 1                 ;   the base-10 logarithm of the number by
    scr r5, 1                 ;   reducing the base-2 exponent.
    test r1, r8               ; * The base-10 exponent is stored as a fixed
    jz .cl_skip_bit           ;   point number with the LSB being 2 ** -41.
    add r2, r5
    adc r3, r6
    adc r4, r7
.cl_skip_bit:
    shr r8, 1
    jnz .coarse_loop
    mov r6, 0
    mov r5, r4                ; * r5 now holds the integer part of the base-10
    jns .r5_se_no_sign        ;   logarithm.
    mov r6, 0xFF80            ; * The bit fiddling here is basically an
.r5_se_no_sign:               ;   arithmetical right shift through r6.
    shr r5, 9
    or r5, r6
    pop r6                    ; * Restore the mantissa into r6_32.
    pop r7
    shl r6, 4                 ; * Shift r6_32 up for use with the digit buffer
    scl r7, 4                 ;   loops later.
    shl r2, 7                 ; * We discard the 7 MSB of the base-10 logarithm
    scl r3, 7                 ;   from r2_48, thus only leaving the fraction
    scl r4, 7                 ;   part in it.
.db_preshift_loop:            ; * The idea is that we take the fraction part of
    cmp r4, 0x6099            ;   the base-10 logarithm later and reduce it to 0
    jnae .db_preshift_done    ;   while also adjusting the digit buffer, much
    sub r2, 0x7DE8            ;   the same way it's done in float_from_string.
    sbb r3, 0x4D42            ; * One problem is that the CORDIC table used
    sbb r4, 0x4D10            ;   there can only reduce the base-10 logarithm
    shl r6, 1                 ;   by log10(2.384) or so which is about 0.377.
    scl r7, 1                 ; * The fraction part of the base-10 logarithm may
    jmp .db_preshift_loop     ;   be anywhere in the range [0; 1). Multiplying
.db_preshift_done:            ;   the digit buffer by 2 and subtracting log10(2)
                              ;   from the base-10 is one way of getting it
                              ;   inside the desired range.
                              ; * The 0x6099 is a lower estimate of the
                              ;   log10(2.384) mentioned earlier.
                              ; * From this point onward r2 is free and we'll
                              ;   consider r3_32 to be the base-10 exponent with
                              ;   the MSB being 2 ** -25 so it can be used with
                              ;   our trusty log10(1 + 2 ** (-n)) CORDIC table.
    push r11                  ; * Incredibly, we're going to need to use these
    push r10                  ;   registers as locals.
    mov r2, 30                ; * Loop with 31 iterations (loop condition
.cordic_fine_loop:            ;   is jnc).
    mov r8, r3                ; * CORDIC time. Subtract entries in the lookup
    mov r9, r4                ;   table from the base-10 exponent and increment
    sub r3, [r2+float_from_string.cordic_table_low]
    sbb r4, [r2+float_from_string.cordic_table_high]
    jc .cfl_restore_r3_32     ;   the base-2 logarithm if the subtraction yields
    mov r1, 31                ;   a positive result.
    sub r1, r2                ; * The constants in the lookup table are
    mov r10, r6               ;   log10(1 + 2 ** (-n)) where n is in the range
    mov r11, r7               ;   [31, 1]. 1 + 2 ** (-n) is easily doable with
    test r1, 0x10             ;   shifts and adds and that's what happens here.
    jz .cfl_no_shift16
    mov r10, r11
    mov r11, 0
.cfl_no_shift16:
    shr r11, r1               ; * r10_32 is shifted down n bits.
    scr r10, r1
    add r6, r10               ; * And with this r6_32 is multiplied by (roughly)
    adc r7, r11               ;   1 + 2 ** (-n).
    jmp .cfl_success
.cfl_restore_r3_32:
    mov r3, r8
    mov r4, r9
.cfl_success:
    shl r3, 1
    scl r4, 1
    sub r2, 1
    jnc .cordic_fine_loop
    pop r10
    pop r11
    mov r8, 0                 ; * r8_32 will hold the BCD representation.
    mov r9, 0
    mov r2, 7                 ; * The BCD extraction loop iterates 7 times,
    cmp r7, 0x5000            ;   except in the special case when the mantissa
    jnae .extract_bcd_loop    ;   exceeds 10 in the CORDIC loop.
    sub r2, 1                 ; * This special case is handled here. The base-10
    add r5, 1                 ;   logarithm is also bumped.
    sub r7, 0x5000
    add r8, 1
    cmp r7, 0x5000
    jnae .extract_bcd_loop
    sub r7, 0x5000
    add r8, 1
.extract_bcd_loop:
    mov r3, r7                ; * Extract MSD from digit buffer,
    shr r3, 11                ;   push it into the BCD buffer.
    shl r8, 4
    scl r9, 4
    or r8, r3
    and r7, 0x7FF             ; * Discard MSD.
    mov r3, r6                ; * Multiply r6_32 by 10.
    mov r4, r7                ; * Basically the following happens:
    shl r3, 2                 ;   * r3_32 = r6_32,
    scl r4, 2                 ;   * r3_32 <<= 2,
    add r6, r3                ;   * r6_32 += r3_32,
    adc r7, r4                ;   * r6_32 <<= 1.
    shl r6, 1                 ; * So in the end (r6_32 * (4 + 1)) * 2 or
    scl r7, 1                 ;   r6_32 * 10 is assigned to r6_32.
    sub r2, 1
    jnz .extract_bcd_loop
    add r8, 0x6666            ; * Rig BCD buffer so that when 1 is added,
    adc r9, 0x666             ;   possible carries propagate correctly.
    cmp r7, 0x2800            ; * See if the next digit that could be
    jnae .no_bump_bcd         ;   extracted from the digit buffer is 5
    add r8, 1                 ;   or more and bump BCD buffer if it is.
    adc r9, 0
    test r9, 0x1000           ; * With this we might overflow the BCD
    jz .no_bcd_bump_overflow  ;   buffer, so that needs to be handled.
    mov r9, 0x700
    add r5, 1
.no_bcd_bump_overflow:
.no_bump_bcd:
    mov r2, 4                 ; * The BCD cleanup loop iterates 4 times.
.clean_bcd_buffer_loop:
    test r8, 0xF000           ; * Due to the previous rigging with 0x6666, all
    jz .no_sub_6000_r8        ;   the digits in the BCD buffer are off by 6,
    sub r8, 0x6000            ;   except the ones that overflowed to 0, which
.no_sub_6000_r8:              ;   should be left alone.
    rol r8, 4                 ; * Correcting the ones that aren't 0 is what
    test r9, 0xF000           ;   happens here.
    jz .no_sub_6000_r9        ; * The four nibbles of the two 16-bit buffer
    sub r9, 0x6000            ;   registers are cleaned up in four iterations
.no_sub_6000_r9:              ;   of the loop.
    rol r9, 4                 ; * Believe me, these ugly conditional jumps
    sub r2, 1                 ;   provide the fastest way to do this.
    jnz .clean_bcd_buffer_loop
    mov r4, 7                 ; * This is where the fancy printing of numbers
    mov r6, 0                 ;   happens. They are printed in scientific
    mov r7, 1                 ;   notation unless the base-10 logarithm, held in
    cmp r5, 0xFFFD            ;   r5, falls in the range [-3; 6] (0xFFFD = -3).
    jl .emit_scientific       ; * When printing in scientific notation, 7 digits
    cmp r5, 6                 ;   are printed. These are numbered from the
    jg .emit_scientific       ;   right, the rightmost being the first.
    cmp r5, 0                 ; * r4 holds the digit after which the decimal
    jge .emit_default         ;   dot is to be printed. r6 is 0 if an explicit
                              ;   exponent is to be printed. r7 is 1 as long as
                              ;   it makes sense to print more digits. All this
                              ;   will be explained later.
    mov r3, r5                ; * If r5 falls in the range [-3; -1], the BCD
    shl r3, 2                 ;   buffer is simply shifted to the right,
    mov r2, 0xFFFF            ;   discarding trailing zeroes.
    shr r2, r3                ; * This is only done if the last digits are
    test r8, r3               ;   actually zeroes, so here the code may still
    jnz .emit_scientific      ;   decide to print the number using vanilla
    mov r2, 0                 ;   scientific notation if that is not the case.
    sub r2, r3                ; * If it is though, it's only a matter of
    shr r9, r2                ;   adding leading zeroes to the BCD buffer and
    scr r8, r2                ;   rigging r5 so that it reflects the shift.
    mov r5, 0
.emit_default:                ; * If r5 falls in the range [0; 6], the decimal
    sub r4, r5                ;   dot is simply shifted to the right. This is
    mov r6, 1                 ;   implemented as a rigged scientific notation
                              ;   with r6 set to 1 so no explicit exponent is
                              ;   printed and r4 decreased by r5.
.emit_scientific:             ; * In the end scientific notation is used in all
    shl r8, 4                 ;   cases, it's just rigged by shifted decimal
    scl r9, 4                 ;   dots, leading zeroes and disabled exponents.
    mov r2, 7                 ; * The BCD emit loop iterates 7 times.
.emit_bcd_loop:
    mov r3, r9                ; * Extract digit from BCD, shift BCD buffer up.
    shl r8, 4
    scl r9, 4
    shr r3, 12
    add r3, '0'
    mov [r0], r3              ; * Store ASCII-coded digit, bump output pointer.
    add r0, 1
    cmp r2, r4                ; * Check if we've reached the point where we
    jne .emit_bcd_no_pfrac    ;   should print the decimal dot. if we have, we
    mov r7, 0                 ;   have no reason to print trailing zeroes
.emit_bcd_no_pfrac:           ;   anymore so 0 is stored into r7.
    mov r3, r9                ; * Check if all we have left is trailing zeroes.
    or r3, r8                 ;   If it is, don't print them unless r7 is 1,
    or r3, r7                 ;   e.g. we haven't reached the decimal dot yet.
    jz .emit_bcd_done
    cmp r2, r4                ; * Print the decimal dot for real this time if
    jne .emit_bcd_no_dot      ;   this is where we should print it.
    mov [r0], '.'
    add r0, 1                 ; * Bump output pointer.
.emit_bcd_no_dot:
    sub r2, 1
    jnz .emit_bcd_loop
.emit_bcd_done:
    test r6, r6               ; * Emit explicit exponent if r6 is 1.
    jnz .exit
    mov [r0], 'e'
    add r0, 1                 ; * Bump output pointer.
    test r5, r5
    jns .base10_exp_no_sign
    mov [r0], '-'
    add r0, 1                 ; * Print a negative sign if the base-10 logarithm
    xor r5, 0xFFFF            ;   is negative. Also negate it so it's easier to
    add r5, 1                 ;   print.
.base10_exp_no_sign:
    mov r4, '0'
    cmp r5, 20                ; * Ugly way to print an unsigned integer between
    jnae .base10_exp_b_20     ;   0 and 39. I'm sure it's obvious what happens
    add r4, 2                 ;   here.
    sub r5, 20
.base10_exp_b_20:
    cmp r5, 10
    jnae .base10_exp_b_10
    add r4, 1
    sub r5, 10
.base10_exp_b_10:
    add r5, '0'
    cmp r4, '0'               ; * Don't emit tens if there's nothing to emit.
    je .no_emit_exp_tens
    mov [r0], r4
    add r0, 1
.no_emit_exp_tens:
    mov [r0], r5
    add r0, 1
.exit:
    mov [r0], 0               ; * Terminate string.
    add r0, 1
    mov r1, r0
    pop r0                    ; * Restore string buffer pointer.
    sub r1, r0                ; * Calculate number of characters written.
    ret
.result_is_zero:
    mov [r0], '0'
    add r0, 1
    jmp .exit
.result_is_inf:
    and r3, 0x007F            ; * Number is nan if any of the bits in the
    or r3, r2                 ;   mantissa are set.
    jnz .result_is_nan
    mov [r0], 'i'
    add r0, 1
    mov [r0], 'n'
    add r0, 1
    mov [r0], 'f'
    add r0, 1
    jmp .exit
.result_is_nan:
    mov [r0], 'n'
    add r0, 1
    mov [r0], 'a'
    add r0, 1
    mov [r0], 'n'
    add r0, 1
    jmp .exit




; * Subtracts one floating point number from another.
; * r2_32 is subtracted from r0_32.
; * Requires a working stack.
float_subtract:
    xor r3, 0x8000            ; * Beware, fallthrough into float_add.




; * Adds one floating point number to another.
; * r2_32 is added to r0_32.
; * Requires a working stack.
float_add:
    mov r4, r1                ; * Compare numbers. In case the absolute value of
    mov r5, r3                ;   r2_32 is bigger than the absolute value of
    and r4, 0x7FFF            ;   r0_32, the two are swapped. This will make it
    and r5, 0x7FFF            ;   easier to do the addition or subtraction
                              ;   later.
    cmp r4, 0x7F80            ; * Check for nans.
    jb .r0_32_is_not_nan
    ja float_epilogue.result_is_nan
    test r0, r0
    jnz float_epilogue.result_is_nan
.r0_32_is_not_nan:
    cmp r5, 0x7F80
    jb .r2_32_is_not_nan
    ja float_epilogue.result_is_nan
    test r2, r2
    jnz float_epilogue.result_is_nan
.r2_32_is_not_nan:
    cmp r0, r2
    cmb r4, r5                ; * Note that to decide which number has a bigger
    jnb .skip_input_swap      ;   absolute value it's sufficient to compare the
    mov r4, r3                ;   31 LSB of the numbers as a 31-bit unsigned
    mov r3, r1                ;   integer. This is an IEEE-754 thing.
    mov r1, r4
    mov r4, r2
    mov r2, r0
    mov r0, r4
.skip_input_swap:
    mov r4, r1                ; * The sign of the result will be the same as the
                              ;   sign of the input with a bigger absolute
                              ;   value.
    mov r8, r4                ; * Do a subtraction instead of an addition if the
    xor r8, r3                ;   signs don't match, i.e. r8 MSB set.
    and r1, 0x7FFF            ; * Discard sign bit, it'd just get in the way.
    and r3, 0x7FFF
    cmp r1, 0x7F80            ; * If either of the numbers is a kind of inf, it
    jne .input_has_no_inf     ;   will end up in r0_32.
    cmp r3, 0x7F80                    ; * If only one of the inputs is an inf,
    jne float_epilogue.result_is_inf  ;   the result is trivial. If both are
    test r8, r8                       ;   infs though, it's a bit trickier as
    js float_epilogue.result_is_nan   ;   differently signed infs add up to a
    jmp float_epilogue.result_is_inf  ;   nan.
.input_has_no_inf:
    mov r5, r1                ; * Store base-2 logarithm in r7.
    and r5, 0x7F80
    mov r7, r5
    mov r6, r3
    and r6, 0x7F80
    sub r5, r6                ; * Extract difference in base-2 logarithms to r5.
    cmp r5, 0xC00                       ; * Skip the whole addition if the
    jae float_epilogue.encode_and_exit  ;   smaller number is too small to be of
    shr r5, 7                           ;   any significance.
    and r1, 0x007F            ; * Get base-2 logarithm out of the way.
    and r3, 0x007F
    or r1, 0x0080             ; * Restore implicit leading one.
    or r3, 0x0080
    test r5, r5
    jz .no_adjust_r2_32
    test r5, 0x10
    jz .no_adjust_r2_32_16
    mov r2, r3
    mov r3, 0
.no_adjust_r2_32_16:
    sub r5, 1
    shr r3, r5                ; * Shift the smaller number down appropriately.
    scr r2, r5
    mov r5, r2                ; * Add last bit shifted out back so as to
    and r5, 1                 ;   mitigate precision loss.
    add r2, r5
    adc r3, 0
    shr r3, 1
    scr r2, 1
.no_adjust_r2_32:
    test r8, r8
    js .do_subtraction
    add r0, r2                ; * Add smaller number to bigger number.
    adc r1, r3
    test r1, 0x0100           ; * Check overflow, shift buffer down, increment
    jz .skip_subtraction      ;   base-2 logarithm if it happens.
    shr r1, 1
    scr r0, 1
    add r7, 0x0080
    cmp r7, 0x7F80                   ; * Check overflow of the base-2 logarithm,
    je float_epilogue.result_is_inf  ;   store inf if it happens.
    jmp .skip_subtraction
.do_subtraction:
    mov r8, 0                 ; * Accumulate amount of right shifts in r8.
    mov r9, 8                 ; * Set up initial shift amount before the
    mov r5, 0xFFFF            ;   normaliser loop to be 8 in r9 and the initial
    sub r0, r2                ;   zero check mask in r5.
    sbb r1, r3
    jnz .no_initial_shift_8
    shl r0, 8
    scl r1, 8
    add r8, 8
.no_initial_shift_8:
.shift_down_loop:             ; * Shift r0_32 up until the implicit leading one
    test r1, r5               ;   bit (0x0080) is set in r1, accumulate amount
    jnz .no_shift_down        ;   of shifts in r8.
    shl r0, r9
    scl r1, r9
    add r8, r9
.no_shift_down:
    shr r9, 1
    shl r5, r9
    test r9, r9
    jnz .shift_down_loop
    shl r8, 7                 ; * Subtract r8 from base-2 logarithm. Return zero
    sub r7, r8                ;   if the base-2 logarithm hits zero or lower.
    jle float_epilogue.result_is_zero
.skip_subtraction:
    test r1, r1
    jz float_epilogue.result_is_zero
    and r1, 0x007F            ; * Discard implicit leading one.
    or r1, r7                 ; * Merge base-2 logarithm back.
                              ; * Beware, fallthrough into common
                              ;   float_epilogue.encode_and_exit.

float_epilogue:
.encode_and_exit:
    and r4, 0x8000
    or r1, r4
    ret
.result_is_nan:
    mov r1, 0x7FFF
    mov r0, 0xFFFF
    jmp .encode_and_exit
.result_is_inf:
    mov r1, 0x7F80
    mov r0, 0x0000
    jmp .encode_and_exit
.result_is_zero:
    mov r1, 0x0000
    mov r0, 0x0000
    jmp .encode_and_exit




; * Multiplies one floating point number with another.
; * r0_32 is multiplied by r2_32.
; * Requires a working stack.
float_multiply:
    mov r4, r1                ; * Calculate final sign bit.
    xor r4, r3
    and r1, 0x7FFF            ; * Discard sign bits.
    jz float_epilogue.result_is_zero
    and r3, 0x7FFF
    jz float_epilogue.result_is_zero
    mov r5, 0                 ; * Check for nans and infs.
    cmp r1, 0x7F80
    jb .r0_32_is_not_nan
    ja float_epilogue.result_is_nan
    test r0, r0
    jnz float_epilogue.result_is_nan
    mov r5, 1
.r0_32_is_not_nan:
    cmp r3, 0x7F80
    jb .r2_32_is_not_nan
    ja float_epilogue.result_is_nan
    test r2, r2
    jnz float_epilogue.result_is_nan
    mov r5, 1
.r2_32_is_not_nan:
    test r5, r5
    jnz float_epilogue.result_is_inf
    mov r5, r1
    mov r6, r3
    and r5, 0x7F80            ; * Extract base-2 logarithm of inputs.
    and r6, 0x7F80
    add r5, r6                ; * Calculate new base-2 logarithm of output.
    sub r5, 0x3F80            ; * Fix double bias.
    and r1, 0x007F            ; * Extract mantissa. This is not done for r2_32.
    or r1, 0x0080             ; * Restore implicit leading ones.
    or r3, 0x0080
    mov [.cache_1_low], r0
    mov [.cache_1_high], r1
    mov [.cache_3_low], r0
    mov [.cache_3_high], r1
    shl r0, 1
    scl r1, 1
    mov [.cache_2_low], r0
    mov [.cache_2_high], r1
    add [.cache_3_low], r0
    adc [.cache_3_high], r1
    mov r0, 0                 ; * r0_32 will act as the result buffer.
    mov r1, 0
    test r2, r2               ; * Not doing any work if it's not needed.
    jz .skip_multiply_loop_low
    mov r7, 8                 ; * r2 is processed in 2-bit packets.
.multiply_loop_low:
    mov r8, r2
    and r8, 0x0003            ; * The r0_32 cache is indexed by the 2 LSB of r2.
    add r0, [r8+.cache_0_low]
    adc r1, [r8+.cache_0_high]
    shr r2, 2
    mov r8, r0                ; * The 2 LSB of r0_32 are discarded, but 1 bit is
    shr r1, 2                 ;   folded back in so as to mitigate precision
    scr r0, 2                 ;   loss.
    shr r8, 1
    and r8, 0x0001
    add r0, r8
    adc r1, 0
    sub r7, 1
    jnz .multiply_loop_low
.skip_multiply_loop_low:
    mov r7, 4                 ; * r3 is processed in 2-bit packets.
.multiply_loop_high:
    mov r8, r3
    and r8, 0x0003            ; * The r0_32 cache is indexed by the 2 LSB of r3.
    add r0, [r8+.cache_0_low]
    adc r1, [r8+.cache_0_high]
    shr r3, 2
    sub r7, 1
    jz .multiply_loop_high_done
    mov r8, r0                ; * The 2 LSB of r0_32 are discarded, but 1 bit is
    shr r1, 2                 ;   folded back in so as to mitigate precision
    scr r0, 2                 ;   loss.
    shr r8, 1
    and r8, 0x0001
    add r0, r8
    adc r1, 0
    jmp .multiply_loop_high
.discard_lsb:
    add r5, 0x0080            ; * Bump base-2 logarithm.
.multiply_loop_high_done:
    mov r8, r0                ; * The LSB of r0_32 is discarded, but 1 bit is
    shr r1, 1                 ;   folded back in so as to mitigate precision
    scr r0, 1                 ;   loss.
    and r8, 0x0001
    add r0, r8
    adc r1, 0
    test r1, 0x0100           ; * The same LSB trickery is done in case an
    jnz .discard_lsb          ;   overflow happens.
.no_overflow:
    cmp r5, 0
    jle float_epilogue.result_is_zero
    cmp r5, 0x7F80
    jge float_epilogue.result_is_inf
    and r1, 0x007F            ; * Discard implicit leading one.
    or r1, r5                 ; * Merge base-2 logarithm back.
    jmp float_epilogue.encode_and_exit
.cache_0_low: dw 0
.cache_1_low: dw 0
.cache_2_low: dw 0
.cache_3_low: dw 0
.cache_0_high: dw 0
.cache_1_high: dw 0
.cache_2_high: dw 0
.cache_3_high: dw 0




; * Divides one floating point number with another.
; * r0_32 is divided by r2_32.
; * Requires a working stack.
float_divide:
    mov r4, r1                ; * Calculate final sign bit.
    xor r4, r3
    and r3, 0x7FFF            ; * Discard sign bits.
    jz float_epilogue.result_is_nan
    and r1, 0x7FFF
    jz float_epilogue.result_is_zero
    mov r5, 0                 ; * Check for nans and infs.
    cmp r1, 0x7F80
    jb .r0_32_is_not_nan
    ja float_epilogue.result_is_nan
    test r0, r0
    jnz float_epilogue.result_is_nan
    or r5, 1
.r0_32_is_not_nan:
    cmp r3, 0x7F80
    jb .r2_32_is_not_nan
    ja float_epilogue.result_is_nan
    test r2, r2
    jnz float_epilogue.result_is_nan
    or r5, 2
.r2_32_is_not_nan:
    jmp [r5+.infnan_jump_able]
.infnan_jump_able:
    dw .result_default                ; * Return (-)(x/y) for (-)x/(-)y
    dw float_epilogue.result_is_inf   ; * Return (-)0 for (-)inf/(-)y
    dw float_epilogue.result_is_zero  ; * Return (-)0 for (-)x/(-)inf
    dw float_epilogue.result_is_nan   ; * Return nan for (-)inf/(-)inf
.result_default:
    mov r5, r1
    mov r6, r3
    and r5, 0x7F80            ; * Extract base-2 logarithm of inputs.
    and r6, 0x7F80
    sub r5, r6                ; * Calculate new base-2 logarithm of output.
    add r5, 0x3F80            ; * Fix cancelled bias.
    and r1, 0x007F            ; * Extract mantissa.
    or r1, 0x0080
    and r3, 0x007F
    or r3, 0x0080
    and r4, 0x8000            ; * We're going to store in the LSB of r4 a bit
    cmp r0, r2                ;   that will signal that the mantissas match.
    cmb r1, r3
    ja .skip_shift
    je .mantissas_match
    sub r5, 0x80              ; * We shift the dividend up as the divisor is
    shl r0, 1                 ;   greater and the quotient would have a leading
    scl r1, 1                 ;   zero Otherwise.
    jmp .skip_shift
.mantissas_match:
    or r4, 1
.skip_shift:
    cmp r5, 0                 ; * Check for overflow.
    jle float_epilogue.result_is_zero
    cmp r5, 0x7F80
    jge float_epilogue.result_is_inf
    test r4, 1                ; * Encode a plain old 1 with an exponent if the
    jnz .result_is_unit_exp   ;   mantissas match.
    push r5
    push r4
    sub r0, r2                ; * The first bit of the quotient would have been
    sbb r1, r3                ;   1 anyway.
    mov r8, 0                 ; * Accumulate the bits of the quotient in here.
    mov r6, 23                ; * Generate 24 bits of the quotient.
    mov r7, 0x40
.division_loop:
    shl r0, 1                 ; * The usual shift-and-add loop. Shift dividend
    scl r1, 1                 ;   up, see if we can subtract the divisor,
    mov r4, r0                ;   don't write back the difference if we can't,
    mov r5, r1                ;   set a bit in the quotient if we can.
    sub r4, r2
    sbb r5, r3
    jb .skip_writeback
    mov r0, r4
    mov r1, r5
    or r8, r7
.skip_writeback:
    sub r6, 1
    jz .loop_done
    ors r4, r5                ; * We can also exit early if we ended up zeroing
    jz .loop_done             ;   the dividend.
    shr r7, 1
    jnz .division_loop
    mov r9, r8
    mov r8, 0
    mov r7, 0x8000
    jmp .division_loop
.loop_done:
    test r6, 16
    jz .skip_pop
    mov r9, r8
    mov r8, 0
.skip_pop:
    shl r0, 1                 ; * Mitigate precision loss.
    scl r1, 1
    cmp r0, r2
    cmb r1, r3
    jb .skip_bump
    add r8, 1
    adc r9, 0
.skip_bump:
    pop r4
    pop r5
    or r9, r5
    mov r0, r8
    mov r1, r9
    jmp float_epilogue.encode_and_exit
.result_is_unit_exp:
    mov r1, r5
    mov r0, 0
    jmp float_epilogue.encode_and_exit




; * Takes the square root of a floating point number.
; * The square root of r0_32 is taken.
; * Requires a working stack.
float_sqrt:
    mov r4, 0
    test r1, 0x8000
    jnz float_epilogue.result_is_nan
    and r1, 0x7FFF            ; * Discard sign bit.
    jz float_epilogue.result_is_zero
    cmp r1, 0x7F80            ; * Check for nans and infs.
    jb .r0_32_is_not_nan
    ja float_epilogue.result_is_nan
    test r0, r0
    jnz float_epilogue.result_is_nan
    jmp float_epilogue.result_is_inf
.r0_32_is_not_nan:
    mov r5, 0                 ; * r5_48 will hold the mantissa of the input.
    mov r6, r0
    mov r7, r1
    and r7, 0x007F
    or r7, 0x0080
    shl r6, 7                 ; * Shift mantissa up by 23 bits.
    scl r7, 7
    mov r3, r1
    and r3, 0x7F80            ; * Extract base-2 logarithm of input.
    sub r3, 0x3F80
    test r3, 0x80             ; * Shift mantissa up by 1 if the exponent is odd.
    jz .skip_shift_up
    sub r3, 0x80
    shl r6, 1
    scl r7, 1
.skip_shift_up:
    cmp r3, 0xC080            ; * Check for underflow (0xC080 = -0x3F80).
    jle float_epilogue.result_is_zero
    shr r3, 1                 ; * Halve the exponent. Basic square root stuff.
    test r3, 0x4000
    jz .no_sign_extend
    or r3, 0x8000
.no_sign_extend:
    mov r0, 0                 ; * r0_48 will hold the mantissa of the output.
    mov r1, 0
    mov r2, 0
    push 0x4000               ; * [sp]_48 will hold the running bit.
    push 0
    push 0
    mov r9, 24                ; * The loop iterates 24 times.
.loop:
    mov [sp-3], r5            ; * This has been taken straight from Wikipedia.
    mov [sp-2], r6            ; * I'm going to be honest here, I didn't even try
    mov [sp-1], r7            ;   to understand how this works. Here's some
    mov r8, 1                 ;   C code for completeness' sake.
    sub r5, r0                ;
    sbb r6, r1                ;   uint64_t isqrt(uint64_t num)
    sbb r7, r2                ;   {
    jc .restore               ;       uint64_t res = 0;
    sub r5, [sp]              ;       uint64_t bit = 1ULL << 46;
    sbb r6, [sp+1]            ;       while (bit != 0)
    sbb r7, [sp+2]            ;       {
    jnc .skip_restore         ;           int flag = 0;
.restore:                     ;           if (num >= res + bit)
    mov r5, [sp-3]            ;           {
    mov r6, [sp-2]            ;               num -= res + bit;
    mov r7, [sp-1]            ;               flag = 1;
    mov r8, 0                 ;           }
.skip_restore:                ;           res >>= 1;
    shr r2, 1                 ;           if (flag)
    scr r1, 1                 ;           {
    scr r0, 1                 ;               res += bit;
    test r8, 1                ;           }
    jz .skip_add              ;           bit >>= 2;
    add r0, [sp]              ;       }
    adc r1, [sp+1]            ;       return res;
    adc r2, [sp+2]            ;   }
.skip_add:                    ;
    shr [sp+2], 2             ; * It just sort of works. It's terribly
    scr [sp+1], 2             ;   unoptimised but it does what it's supposed to.
    scr [sp], 2
    sub r9, 1
    jnz .loop
    add sp, 3                 ; * Pop running bit off the stack.
    test r1, 0x100
    jz .skip_shift_down
    add r3, 0x80
    shr r1, 1
    scr r0, 1
.skip_shift_down:
    and r1, 0x007F
    add r3, 0x3F80
    or r1, r3
    jmp float_epilogue.encode_and_exit

