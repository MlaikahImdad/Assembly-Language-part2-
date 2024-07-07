; reverse each character of screen font
[org 0x0100]

jmp start

font:       times 256*16 db 0               ; space for font

start:      mov ax, 0x1130                  ; service 11/30 – get font info
            mov bx, 0x0600                  ; ROM 8x16 font
            int 0x10                        ; bios video services

            mov si, bp                      ; point si to rom font data
            mov di, font                    ; point di to space for font
            mov cx, 256*16                  ; font size
            push ds
            push es
            pop ds                          ; ds:si to rom font data
            pop es                          ; es:di to space for font
            cld                             ; auto increment mode
            rep movsb                       ; copy font

            push cs
            pop ds                          ; restore ds to data segment
            
            mov si, font                    ; point si to start of font

change:     mov al, [si]                    ; read one byte
            mov cx, 8

inner:      shl al, 1                       ; shift left with MSB in carry
            rcr bl, 1                       ; rotate right using carry
            loop inner                      ; repeat eight times
            mov [si], bl                    ; write back reversed byte
            inc si                          ; next byte of font
            cmp si, font+256*16             ; is whole font reversed
            jne change                      ; no, reverse next byte
            
            mov bp, font                    ; es:bp points to new font
            mov bx, 0x1000                  ; bytes per char & block number
            mov cx, 0x100                   ; number of characters to change
            xor dx, dx                      ; first character to change
            mov ax, 0x1110                  ; service 11/10 – load user font
            int 0x10                        ; bios video services

mov ax, 0x4c00                              ; terminate program
int 0x21