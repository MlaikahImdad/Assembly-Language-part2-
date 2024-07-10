; buffer input using dos services
[org 0x0100]

jmp start

message: db 10,13,'hello ', 10, 13, '$'
buffer:  db 80                                  ; length of buffer
         db 0                                   ; number of character on return
         times 80 db 0                          ; actual buffer space

start:      mov dx, buffer                      ; input buffer
            mov ah, 0x0A                        ; service A – buffered input
            int 0x21                            ; dos services

            mov bh, 0
            mov bl, [buffer+1]                  ; read actual size in bx
            mov byte [buffer+2+bx], '$'         ; append $ to user input

            mov dx, message                     ; greetings message
            mov ah, 9                           ; service 9 – write string
            int 0x21                            ; dos services
            
            mov dx, buffer+2                    ; user input buffer
            mov ah, 9                           ; service 9 – write string
            int 0x21                            ; dos services

mov ax, 0x4c00 ; terminate program
int 0x21