; * WORK IN PROGRESS, PLEASE IGNORE.

start:                                  ; * TODO: Comments.
    mov sp, 0
    mov r10, 0
    send r10, 0x200F
    mov r1, 11
.reset_loop:
    mov r0, [r1+.buffer_0]
    mov [r1+.buffer_a], r0
    sub r1, 1
    jnc .reset_loop
    mov r6, .buffer_a
    mov r7, .buffer_b
.frame_loop:
    send r10, 0x1010
    mov r1, 10
    add r6, 11
.draw_loop:
    mov r2, 16
    mov r0, [r6-r1]
    jmp .draw_row_loop_enty
.draw_row_loop:
    shl r0, 1
.draw_row_loop_enty:
    js .draw_life
    send r10, ' '
    jmp .skip_life
.draw_life:
    send r10, 0x7F
.skip_life:
    sub r2, 1
    jnz .draw_row_loop
    sub r1, 1
    jnz .draw_loop
    sub r6, 10
    mov r5, 10
.row_loop:
    mov r0, 0
    mov r1, 0
    mov r2, 0
    mov r3, [r6+r5]
    shl r3, 1
    call .smart_add
    mov r3, [r6+r5]
    shr r3, 1
    call .smart_add
    sub r5, 1
    mov r3, [r6+r5]
    call .smart_add
    shl r3, 1
    call .smart_add
    mov r3, [r6+r5]
    shr r3, 1
    call .smart_add
    add r5, 2
    mov r3, [r6+r5]
    call .smart_add
    shl r3, 1
    call .smart_add
    mov r3, [r6+r5]
    shr r3, 1
    call .smart_add
    xor r2, 0xFFFF
    mov r3, r1
    and r0, r1
    and r0, r2
    and r3, r2
    sub r5, 1
    and r0, [r6+r5]
    or r0, r3
    mov [r7+r5], r0
    sub r5, 1
    jnz .row_loop
    sub r6, 1
    mov r0, r6
    mov r6, r7
    mov r7, r0
    jmp .frame_loop
.smart_add:
    mov r4, r3
    and r4, r0
    xor r0, r3
    mov r3, r4
    and r3, r1
    xor r1, r4
    or r2, r4
    ret
.buffer_0:
    dw 0x0000, 0x1000, 0x5000, 0x3000, 0x0000, 0x0000
    dw 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
.buffer_a:
    dw 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
    dw 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
.buffer_b:
    dw 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
    dw 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
