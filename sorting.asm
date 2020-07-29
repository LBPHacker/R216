; * This is the source code for the program used in
;   https://powdertoy.co.uk/Browse/View.html?ID=2368015


%include "common"


start:
    mov sp, 0                 ; * Initialise stack pointer.
    mov r10, 0                ; * r10 holds the address of the port
                              ;   the terminal is connected to.
    mov r12, 1                ; * r12 holds the address of the port
                              ;   the demo peripheral is connected to.
    mov r13, 2                ; * r13 holds the address of the port
                              ;   the shuffler switch to (see more below).
    bump r10                  ; * Reset terminal.
    send r13, 1               ; * Switch the demo peripheral to sorting mode.
.menu_loop:
    mov r0, .main_menu
    call menu
    jmp .menu_loop
.main_menu:
    dw shuffle, "Shuffle", 0
    dw quicksort, "Quicksort", 0
    dw heapsort, "Heapsort", 0
    dw bubble_sort, "Bubble Sort", 0
    dw insertion_sort, "Insertion S", 0
    dw selection_sort, "Selection S", 0
    dw ugly_hax, "Ugly Hacks", 0
    dw .shutdown, "Shutdown", 0
    dw 0
.shutdown:
    hlt
    jmp start



; * Displays a menu with numbered options and lets the user choose from them.
; * r0 points to menu structure. This has the following layout:
;   * Menu items consist of a subroutine pointer. An entry with a null pointer
;     signifies the end of the list.
;   * After the subroutine pointer, a zero-terminated string is present that is
;     displayed on screen when the menu is shown.
;   * There may be no more than 8 entries.
; * Note: The subroutine pointers are jumped to instead of being called (this is
;   known as a tail call).
menu:
    push r0                   ; * Save pointer for later when the text is
                              ;   cleared.
    send r10, 0x200F          ; * White foreground, black background.
    mov r3, 0                 ; * Initialise entry counter.
    mov r5, 0x1011            ; * Row 1, column 1.
.entries_loop:
    mov r4, [r0]              ; * Check subroutine pointer.
    jz .entries_done          ; * Exit loop if zero.
    mov [.subroutine_pointers+r3], r4
    add r3, 1                 ; * Increment entry counter.
    add r0, 1                 ; * Go on to the string to be displayed.
    send r10, r5              ; * Set cursor position.
    add r5, 0x10              ; * Go to next row.
    add r3, '0'               ; * Display "%i) %s" where %i is r3 and %s is the
    send r10, r3              ;   display string associated with the subroutine.
    sub r3, '0'
    send r10, ')'
    send r10, ' '
    call write_string
    add r0, 1                 ; * Go on the the next subroutine pointer.
    cmp r3, 8                 ; * Exit loop early if the entry limit is reached.
    jb .entries_loop
.entries_done:
    mov r0, .press_str
    call write_string
    add r3, '0'               ; * Display "Press 1-%i" where %i is r3.
    send r10, r3
    push r3
.input_loop:
    mov r6, 0x200F            ; * Read user choice.
    mov r11, 0x10AC
    call read_character_blink
    cmp r3, '0'               ; * Sanitise input.
    jbe .input_loop
    cmp r3, [sp]              ; * Note that count + '0' is stored in [sp].
    ja .input_loop
    pop r4                    ; * Pop count + '0'.
    sub r4, '0'
    pop r0                    ; * Restore menu structure pointer.
    send r10, 0x2000          ; * Black foreground, black background.
    mov r5, 0x1011            ; * Row 1, column 1.
.clear_loop:
    send r10, r5              ; * Set cursor position.
    add r5, 0x10              ; * Go to next row.
    send r10, ' '
    send r10, ' '
    send r10, ' '
    add r0, 1
    call write_string         ; * Clear "%i) %s" string.
    add r0, 1
    sub r4, 1
    jnz .clear_loop
    mov r0, .press_str
    call write_string         ; * Clear "Press 1-%i" string.
    send r10, ' '
    send r10, ' '
    sub r3, '1'               ; * Calculate offset into .subroutine_pointers.
    jmp [.subroutine_pointers+r3]
.subroutine_pointers:
    dw 0, 0, 0, 0, 0, 0, 0, 0
.press_str:
    dw 0x10A3, "Press 1-", 0




; * Switches the demo peripheral to shuffling mode, then waits for user input,
;   and finally switches the demo peripheral back to sorting mode. The dataset
;   is externally shuffled until user input arrives.
shuffle:
    send r13, 2               ; * Switch the demo peripheral to shuffling mode.
    mov r0, .dummy_menu
    call menu
    send r13, 1               ; * Switch the demo peripheral to sorting mode.
    ret
.dummy_menu:
    dw .nothing, "Stop", 0
    dw 0
.nothing:
    ret




; * Ugly hacks. This algorithm exploits the fact that the values in the dataset
;   (regardless of order) actually match their final position in the sorted
;   dataset. This is basically radix sort. Its purpose is to remind everyone
;   comparison sorting isn't always the answer.
ugly_hax:
    call dataset.import
    mov r5, [dataset.size]
    sub r5, 1
.reverse_loop:
    mov r0, [dataset+r5]
    mov [.reverse_dataset+r0], r5
    sub r5, 1
    jnc .reverse_loop
    mov r5, [dataset.size]
    sub r5, 1
.hacks_loop:
    mov r0, [.reverse_dataset+r5]
    mov r6, [dataset+r5]
    mov r1, r5
    call dataset.swap
    mov [.reverse_dataset+r6], r0
    sub r5, 1
    jnc .hacks_loop
    ret
; * 36 cells for the reverse dataset imported from the demo peripheral.
.reverse_dataset:
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0




; * Executes quicksort on the dataset.
; * https://en.wikipedia.org/wiki/Quicksort
quicksort:
    call dataset.import
    mov r4, 0
    mov r5, [dataset.size]
    sub r5, 1
.recursive:
    cmp r4, r5
    jnl .recursive_done
    call .partition
    push r5
    mov r5, r6
    sub r5, 1
    push r6
    call .recursive
    pop r6
    pop r5
    push r4
    mov r4, r6
    add r4, 1
    call .recursive
    pop r4
.recursive_done:
    ret
.partition:
    mov r7, [dataset+r5]
    mov r6, r4
    mov r8, r4
.partition_loop:
    cmp r7, [dataset+r8]
    jna .no_swap
    mov r0, r6
    mov r1, r8
    call dataset.swap
    add r6, 1
.no_swap:
    add r8, 1
    cmp r8, r5
    jne .partition_loop
    mov r0, r6
    mov r1, r5
    call dataset.swap
    ret




; * Executes selection sort on the dataset.
; * https://en.wikipedia.org/wiki/Selection_sort
selection_sort:
    call dataset.import
    mov r9, [dataset.size]
    sub r9, 2
.outer_loop:
    mov r8, r9
    mov r0, r8
    add r0, 1
    mov r6, [dataset+r0]
.inner_loop:
    mov r1, [dataset+r8]
    cmp r1, r6
    jna .no_mark
    mov r0, r8
    mov r6, r1
.no_mark:
    sub r8, 1
    jnc .inner_loop
    mov r1, r9
    add r1, 1
    call dataset.swap
    sub r9, 1
    jnc .outer_loop
    ret




; * Executes insertion sort on the dataset.
; * https://en.wikipedia.org/wiki/Insertion_sort
insertion_sort:
    call dataset.import
    mov r9, [dataset.size]
    mov r6, dataset
    sub r6, 1
    mov r8, 1
.outer_loop:
    cmp r8, r9
    jnb .outer_done
    mov r0, r8
.inner_loop:
    cmp r0, 0
    jna .inner_done
    mov r1, [r6+r0]
    cmp r1, [dataset+r0]
    jna .inner_done
    mov r1, r0
    sub r1, 1
    call dataset.swap
    sub r0, 1
    jmp .inner_loop
.inner_done:
    add r8, 1
    jmp .outer_loop
.outer_done:
    ret




; * Executes bubble sort on the dataset.
; * https://en.wikipedia.org/wiki/Bubble_sort
bubble_sort:
    call dataset.import
    mov r9, [dataset.size]
    mov r7, dataset
    add r7, 1
    sub r9, 1
.outer_loop:
    mov r8, r9
    mov r0, 0
.inner_loop:
    mov r4, [dataset+r0]
    cmp r4, [r7+r0]
    jna .no_swap
    mov r1, r0
    add r1, 1
    call dataset.swap
.no_swap:
    add r0, 1
    sub r8, 1
    jnz .inner_loop
    sub r9, 1
    jnz .outer_loop
    ret




; * Executes heapsort on the dataset.
; * https://en.wikipedia.org/wiki/Heapsort
heapsort:
    call dataset.import
    mov r9, [dataset.size]
    mov r8, r9
    sub r8, 1
    shr r8, 1
.heapify_loop:
    mov r0, r8
    call .sink_down
    sub r8, 1
    jnc .heapify_loop
.findmax_loop:
    mov r0, 0
    sub r9, 1
    mov r1, r9
    call dataset.swap
    call .sink_down
    test r9, r9
    jnz .findmax_loop
    ret
.sink_down:
    mov r4, [dataset+r0]
    mov r2, r0
    shl r2, 1
    add r2, 1
    cmp r2, r9
    jae .forget_both
    mov r3, r2
    add r3, 1
    cmp r3, r9
    jae .forget_right
    mov r5, [dataset+r2]
    cmp r5, [dataset+r3]
    jae .forget_right
    mov r2, r3
.forget_right:
    cmp r4, [dataset+r2]
    jae .forget_both
    push r2
    push r1
    mov r1, r2
    call dataset.swap
    pop r1
    pop r0
    jmp .sink_down
.forget_both:
    ret





; * 36 cells for the dataset imported from the demo peripheral.
dataset:
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0
.size: 
    dw 36
; * Imports dataset from demo peripheral.
.import:
    mov r12, 1
    mov r1, dataset
    bump r12
.recv_loop:
    recv r0, r12
    jnc .recv_loop            ; * The carry bit is set if something is received.
    recv [r1+34], r12         ; * I need a better assembler.
    recv [r1+33], r12
    recv [r1+32], r12
    recv [r1+31], r12
    recv [r1+30], r12
    recv [r1+29], r12
    recv [r1+28], r12
    recv [r1+27], r12
    recv [r1+26], r12
    recv [r1+25], r12
    recv [r1+24], r12
    recv [r1+23], r12
    recv [r1+22], r12
    recv [r1+21], r12
    recv [r1+20], r12
    recv [r1+19], r12
    recv [r1+18], r12
    recv [r1+17], r12
    recv [r1+16], r12
    recv [r1+15], r12
    recv [r1+14], r12
    recv [r1+13], r12
    recv [r1+12], r12
    recv [r1+11], r12
    recv [r1+10], r12
    recv [r1+ 9], r12
    recv [r1+ 8], r12
    recv [r1+ 7], r12
    recv [r1+ 6], r12
    recv [r1+ 5], r12
    recv [r1+ 4], r12
    recv [r1+ 3], r12
    recv [r1+ 2], r12
    recv [r1+ 1], r12
    recv [r1   ], r12
    mov [r1+35], r0           ; * This is the value we received first.
    ret
; * Swaps the elements r0 and r1 in the dataset.
.swap:
    mov r2, [dataset+r0]      ; * Do the swap locally.
    mov r3, [dataset+r1]
    mov [dataset+r0], r3
    mov [dataset+r1], r2
    shl r1, 8                 ; * Build swap message for demo peripheral.
    or r1, r0
    send r12, r1              ; * Magic.
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

