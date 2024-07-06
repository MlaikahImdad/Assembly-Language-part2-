; multitasking TSR caller
[org 0x0100]

jmp start

; parameter block layout:
; cs,ip,ds,es,param
; 0, 2, 4, 6, 8
paramblock: times 5 dw 0                        ; space for parameters
lineno: dw 0                                    ; line number for next thread

; subroutine to print a number on screen
; takes the row no, column no, and number to be printed as parameters
printnum:       push bp
                mov bp, sp
                push es
                push ax
                push bx
                push cx
                push dx
                push di
                mov di, 80                      ; load di with columns per row
                mov ax, [bp+8]                  ; load ax with row number
                mul di                          ; multiply with columns per row
                mov di, ax                      ; save result in di
                add di, [bp+6]                  ; add column number
                shl di, 1                       ; turn into byte count
                add di, 8                       ; to end of number location
                mov ax, 0xb800
                mov es, ax                      ; point es to video base
                mov ax, [bp+4]                  ; load number in ax
                mov bx, 16                      ; use base 16 for division
                mov cx, 4                       ; initialize count of digits

nextdigit:      mov dx, 0                       ; zero upper half of dividend
                div bx                          ; divide by 10
                add dl, 0x30                    ; convert digit into ascii value
                cmp dl, 0x39                    ; is the digit an alphabet
                jbe skipalpha                   ; no, skip addition
                add dl, 7                       ; yes, make in alphabet code

skipalpha:      mov dh, 0x07                    ; attach normal attribute
                mov [es:di], dx                 ; print char on screen
                sub di, 2                       ; to previous screen location
                loop nextdigit                  ; if no divide it again
                pop di
                pop dx
                pop cx
                pop bx
                pop ax
                pop es
                pop bp
                ret 6

; subroutine to be run as a thread
; takes line number as parameter
mytask:         push bp
                mov bp, sp
                sub sp, 2                       ; thread local variable
                push ax
                push bx

                mov ax, [bp+4]                  ; load line number parameter
                mov bx, 70                      ; use column number 70
                mov word [bp-2], 0              ; initialize local variable

printagain:     push ax                         ; line number
                push bx                         ; column number
                push word [bp-2]                ; number to be printed
                call printnum                   ; print the number
                inc word [bp-2]                 ; increment the local variable
                jmp printagain                  ; infinitely print

                pop bx
                pop ax
                mov sp, bp
                pop bp
                retf

start:          mov ah, 0                       ; service 0 – get keystroke
                int 0x16                        ; bios keyboard services

                mov [paramblock+0], cs          ; code segment parameter
                mov word [paramblock+2], mytask ; offset parameter
                mov [paramblock+4], ds          ; data segment parameter
                mov [paramblock+6], es          ; extra segment parameter
                mov ax, [lineno]
                mov [paramblock+8], ax          ; parameter for thread
                mov si, paramblock              ; address of param block in si
                int 0x80                        ; multitasking kernel interrupt
                
                inc word [lineno]               ; update line number
                jmp start                       ; wait for next key