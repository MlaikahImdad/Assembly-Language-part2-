; another multitasking TSR caller
[org 0x0100]

jmp start

; parameter block layout:
; cs,ip,ds,es,param
; 0, 2, 4, 6, 8
paramblock: times 5 dw 0                        ; space for parameters
lineno: dw 0                                    ; line number for next thread
chars: db '\|/-'                                ; chracters for rotating bar
message: db 'moving hello'                      ; moving string
message2: db ' '                                ; to erase previous string
messagelen: dw 12                               ; length of above strings

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

; subroutine to print a string
; takes row no, column no, address of string, and its length
; as parameters
printstr:       push bp
                mov bp, sp
                push es
                push ax
                push bx
                push cx
                push dx
                push si
                push di
                mov ax, 0xb800
                mov es, ax                      ; point es to video base
                mov di, 80                      ; load di with columns per row
                mov ax, [bp+10]                 ; load ax with row number
                mul di                          ; multiply with columns per row
                mov di, ax                      ; save result in di
                add di, [bp+8]                  ; add column number
                shl di, 1                       ; turn into byte count
                mov si, [bp+6]                  ; string to be printed
                mov cx, [bp+4]                  ; length of string
                mov ah, 0x07                    ; normal attribute is fixed

nextchar:       mov al, [si]                    ; load next char of string
                mov [es:di], ax                 ; show next char on screen
                add di, 2                       ; move to next screen location
                add si, 1                       ; move to next char
                loop nextchar                   ; repeat the operation cx times
                pop di
                pop si
                pop dx
                pop cx
                pop bx
                pop ax
                pop es
                pop bp
                ret 8

; subroutine to run as first thread
mytask:         push bp
                mov bp, sp
                sub sp, 2                       ; thread local variable
                push ax
                push bx
                xor ax, ax                      ; use line number 0
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

; subroutine to run as second thread
mytask2:        push ax
                push bx
                push es
                mov ax, 0xb800
                mov es, ax                      ; point es to video base
                xor bx, bx                      ; initialize to use first shape

rotateagain:    mov al, [chars+bx]              ; read current shape
                mov [es:40], al                 ; print at specified place
                inc bx                          ; update to next shape
                and bx, 3                       ; take modulus with 4
                jmp rotateagain                 ; repeat infinitely
                pop es
                pop bx
                pop ax
                retf

; subroutine to run as third thread
mytask3:        push bp
                mov bp, sp
                sub sp, 2                       ; thread local variable
                push ax
                push bx
                push cx
                mov word [bp-2], 0              ; initialize line number to 0

nextline:       push word [bp-2]                ; line number
                mov bx, 50
                push bx                         ; column number 50
                mov ax, message
                push ax                         ; offset of string
                push word [messagelen]          ; length of string
                call printstr                   ; print the string
                mov cx, 0x100

waithere:       push cx                         ; save outer loop counter
                mov cx, 0xffff
                loop $                          ; repeat ffff times
                pop cx                          ; restore outer loop counter
                loop waithere                   ; repeat 0x100 times
                push word [bp-2]                ; line number
                mov bx, 50                      ; column number 50
                push bx
                mov ax, message2
                push ax                         ; offset of blank string
                push word [messagelen]          ; length of string
                call printstr                   ; print the string
                inc word [bp-2]                 ; update line number
                cmp word [bp-2], 25             ; is this the last line
                jne skipreset                   ; no, proceed to draw
                mov word [bp-2], 0              ; yes, reset line number to 0

skipreset:      jmp nextline                    ; proceed with next drawing
                pop cx
                pop bx
                pop ax
                mov sp, bp
                pop bp
                retf

start:          mov [paramblock+0], cs          ; code segment parameter
                mov word [paramblock+2], mytask ; offset parameter
                mov [paramblock+4], ds          ; data segment parameter
                mov [paramblock+6], es          ; extra segment parameter
                mov word [paramblock+8], 0      ; parameter for thread
                mov si, paramblock              ; address of param block in si
                int 0x80                        ; multitasking kernel interrupt
                mov [paramblock+0], cs          ; code segment parameter
                mov word [paramblock+2], mytask2 ; offset parameter
                mov [paramblock+4], ds          ; data segment parameter
                mov [paramblock+6], es          ; extra segment parameter
                mov word [paramblock+8], 0      ; parameter for thread
                mov si, paramblock              ; address of param block in si
                int 0x80                        ; multitasking kernel interrupt
                mov [paramblock+0], cs          ; code segment parameter
                mov word [paramblock+2], mytask3 ; offset parameter
                mov [paramblock+4], ds          ; data segment parameter
                mov [paramblock+6], es          ; extra segment parameter
                mov word [paramblock+8], 0      ; parameter for thread
                mov si, paramblock              ; address of param block in si
                int 0x80                        ; multitasking kernel interrupt
                jmp $