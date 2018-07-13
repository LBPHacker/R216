; * WORK IN PROGRESS, PLEASE IGNORE.

; * This program makes use of the stack pointer, so it is first initialised to 0
;   and is rarely (never?) written to explicitly.
; * The calling convention used in this program is as follows:
;   * r0 through r9 are saved by the caller,
;   * r10 through r13 are saved by the callee,
;   * arguments are passed and results are returned in caller-saved registers.

start:
    mov sp, 0                 ; * Zero put sp.
    mov r10, 0                ; * terminal should be connected to port 0.
    bump r10                  ; * Reset terminal.


.game:
	mov r1, world
	mov [r1+0x64], 1
	mov [r1+0x65], 1
	mov [r1+0x66], 1
	send r10, 0x200F
	send r10, 0x1064
	send r10, 0x7F
	send r10, 0x7F
	send r10, 0x7F
	mov r2, 0
	mov r3, 6
	mov r4, 6
.main_loop:
	wait r10
	jns .no_key
	bump r10
.recv_loop:
	recv r0, r10
	jnc .recv_loop
	cmp r0, 's'
	je .key_s
	jb .key_a_d
	cmp r0, 'w'
	jne .no_key
	mov r2, 1
	jmp .no_key
.key_s:
	mov r2, 3
	jmp .no_key
.key_a_d:
	cmp r0, 'a'
	je .key_a
	cmp r0, 'd'
	jne .no_key
	mov r2, 0
	jmp .no_key
.key_a:
	mov r2, 2
.no_key:
	mov r0, 1
	test r2, 2
	jz .no_ffff
	mov r0, -1
.no_ffff:
	test r2, 1
	jz .add_to_r3
	add r4, r0
	jmp .added_to_r4
.add_to_r3:
	add r3, r0
.added_to_r4:

	

	jmp .main_loop

world:                        ; * 16*12 cells for the RT2812A.
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
