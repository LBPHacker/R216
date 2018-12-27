; * WORK IN PROGRESS, PLEASE IGNORE.

start:
	mov r10, 0
	bump r10
	send r10, 0x1000
	send r10, 0x2008
	mov r1, 0x9F
	mov r0, 24
.loop:
	send r10, r1
	send r10, r1
	send r10, r1
	send r10, r1
	send r10, r1
	send r10, r1
	send r10, r1
	send r10, r1
	sub r0, 1
	jnz .loop
	mov r0, .pls
	call write_string
.die:
	hlt
	jmp .die
.pls:
	dw 0x1017, 0x2000, "0"
	dw 0x1025, 0x2009, "1"
	dw 0x1033, 0x200A, "2"
	dw 0x1041, 0x200C, "3"
	dw 0x104F, 0x200D, "4"
	dw 0x105D, 0x2004, "5"
	dw 0x106B, 0x200B, "6"
	dw 0x1079, 0x200F, "7"
	dw 0x1087, 0x200E, "8"
	dw 0x1095, 0x20C0, "\x80"
	dw 0x10A3, 0x20E0, "!"
	dw 0x10B1, 0x20E0, "\x80"
	dw 0




; * Writes zero-terminated strings to the terminal.
; * r0 points to buffer to write from.
; * r10 is terminal port address.
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
