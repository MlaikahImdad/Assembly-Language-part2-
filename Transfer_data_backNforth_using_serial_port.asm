; a program using serial port to transfer data back and forth
[org 0x0100]

jmp start

screenpos:      dw 0                    ; where to display next character

; subroutine to clear the screen
clrscr:         push es
                push ax
                push cx
                push di

                mov ax, 0xb800
                mov es, ax              ; point es to video base
                xor di, di              ; point di to top left column
                mov ax, 0x0720          ; space char in normal attribute
                mov cx, 2000            ; number of screen locations

                cld                     ; auto increment mode
                rep stosw               ; clear the whole screen

                pop di
                pop cx
                pop ax
                pop es
                ret

serial:         push ax
                push bx
                push dx
                push es

                mov dx, 0x3FA           ; interrupt identification register
                in al, dx               ; read register
                and al, 0x0F            ; leave lowerniblle only
                cmp al, 4               ; is receiver data available
                jne skipall             ; no, leave interrupt handler

                mov dx, 0x3F8           ; data register
                in al, dx               ; read character

                mov dx, 0xB800
                mov es, dx              ; point es to video memory
                mov bx, [cs:screenpos]  ; get current screen position
                mov [es:bx], al         ; write character on screen
                add word [cs:screenpos], 2 ; update screen position
                cmp word [cs:screenpos], 4000 ; is the screen full
                jne skipall             ; no, leave interrupt handler

                call clrscr             ; clear the screen
                mov word [cs:screenpos], 0 ; reset screen position

skipall:        mov al, 0x20
                out 0x20, al            ; end of interrupt

                pop es
                pop dx
                pop bx
                pop ax
                iret

start:          call clrscr             ; clear the screen

                mov ah, 0               ; initialize port service
                mov al, 0xE3            ; line settings = 9600, 8, N, 1
                xor dx, dx              ; port = COM1
                int 0x14                ; BIOS serial port services

                xor ax, ax
                mov es, ax              ; point es to IVT base
                mov word [es:0x0C*4], serial
                mov [es:0x0C*4+2], cs   ; hook serial port interrupt

                mov dx, 0x3FC           ; modem control register
                in al, dx               ; read register
                or al, 8                ; enable bit 3 (OUT2)
                out dx, al              ; write back to register

                mov dx, 0x3F9           ; interrupt enable register
                in al, dx               ; read register
                or al, 1                ; receiver data interrupt enable
                out dx, al              ; write back to register

                in al, 0x21             ; read interrupt mask register
                and al, 0xEF            ; enable IRQ 4
                out 0x21, al            ; write back to register

main:           mov ah, 0               ; read key service
                int 0x16                ; BIOS keybaord services
                push ax                 ; save key for later use

retest:         mov ah, 3               ; get line status
                xor dx, dx              ; port = COM1
                int 0x14                ; BIOS keyboard services
                and ah, 32              ; trasmitter holding register empty
                jz retest               ; no, test again

                pop ax                  ; load saved key
                mov dx, 0x3F8           ; data port
                out dx, al              ; send on serial port
                
                jmp main