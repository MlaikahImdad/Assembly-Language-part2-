; elementary multitasking of two threads
[org 0x0100]

jmp start

; ax,bx,ip,cs,flags storage area
taskstates: dw 0, 0, 0, 0, 0                    ; task0 regs
            dw 0, 0, 0, 0, 0                    ; task1 regs
            dw 0, 0, 0, 0, 0                    ; task2 regs

current:    db 0                                ; index of current task
chars:      db '\|/-'                           ; shapes to form a bar

; one task to be multitasked
taskone:    mov al, [chars+bx]                  ; read the next shape
            mov [es:0], al                      ; write at top left of screen
            inc bx                              ; increment to next shape
            and bx, 3                           ; taking modulus by 4
            jmp taskone                         ; infinite task

; second task to be multitasked
tasktwo:    mov al, [chars+bx]                  ; read the next shape
            mov [es:158], al                    ; write at top right of screen
            inc bx                              ; increment to next shape
            and bx, 3                           ; taking modulus by 4
            jmp tasktwo                         ; infinite task

; timer interrupt service routine
timer:      push ax
            push bx

            mov bl, [cs:current]                ; read index of current task
            mov ax, 10                          ; space used by one task
            mul bl                              ; multiply to get start of task
            mov bx, ax                          ; load start of task in bx

            pop ax                              ; read original value of bx
            mov [cs:taskstates+bx+2], ax        ; space for current task
            pop ax                              ; read original value of ax
            mov [cs:taskstates+bx+0], ax        ; space for current task
            pop ax                              ; read original value of ip
            mov [cs:taskstates+bx+4], ax        ; space for current task
            pop ax                              ; read original value of cs
            mov [cs:taskstates+bx+6], ax        ; space for current task
            pop ax                              ; read original value of flags
            mov [cs:taskstates+bx+8], ax        ; space for current task

            inc byte [cs:current]               ; update current task index
            cmp byte [cs:current], 3            ; is task index out of range
            jne skipreset                       ; no, proceed
            mov byte [cs:current], 0            ; yes, reset to task 0

skipreset:  mov bl, [cs:current]                ; read index of current task
            mov ax, 10                          ; space used by one task
            mul bl                              ; multiply to get start of task
            mov bx, ax                          ; load start of task in bx

            mov al, 0x20
            out 0x20, al                        ; send EOI to PIC

            push word [cs:taskstates+bx+8]      ; flags of new task
            push word [cs:taskstates+bx+6]      ; cs of new task
            push word [cs:taskstates+bx+4]      ; ip of new task
            mov ax, [cs:taskstates+bx+0]        ; ax of new task
            mov bx, [cs:taskstates+bx+2]        ; bx of new task
            iret                                ; return to new task

start:      mov word [taskstates+10+4], taskone ; initialize ip
            mov [taskstates+10+6], cs           ; initialize cs
            mov word [taskstates+10+8], 0x0200  ; initialize flags
            mov word [taskstates+20+4], tasktwo ; initialize ip
            mov [taskstates+20+6], cs           ; initialize cs
            mov word [taskstates+20+8], 0x0200  ; initialize flags
            mov word [current], 0               ; set current task index

            xor ax, ax
            mov es, ax                          ; point es to IVT base
            cli
            mov word [es:8*4], timer
            mov [es:8*4+2], cs                  ; hook timer interrupt
            mov ax, 0xb800
            mov es, ax                          ; point es to video base
            xor bx, bx                          ; initialize bx for tasks
            sti
            
            jmp $                               ; infinite loop