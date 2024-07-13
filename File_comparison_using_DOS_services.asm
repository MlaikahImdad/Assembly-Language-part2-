; file comparison using dos services
[org 0x0100]

jmp start

filename1:      times 128 db 0                                      ; space for first filename
filename2:      times 128 db 0                                      ; space for second filename
handle1:        dw 0                                                ; handle for first file
handle2:        dw 0                                                ; handle for second file
buffer1:        times 4096 db 0                                     ; buffer for first file
buffer2:        times 4096 db 0                                     ; buffer for second file

format:         db 'Usage error: diff <filename1> <filename2>$'
openfailed:     db 'First file could not be opened$'
openfailed2:    db 'Second file could not be opened$'
readfailed:     db 'First file could not be read$'
readfailed2:    db 'Second file could not be read$'
different:      db 'Files are different$'
same:           db 'Files are same$'

start:          mov ch, 0
                mov cl, [0x80]                                      ; command tail length in cx
                dec cx                                              ; leave the first space
                mov di, 0x82                                        ; start of command tail in di
                mov al, 0x20                                        ; space for parameter separation
                cld                                                 ; auto increment mode
                repne scasb                                         ; search space
                je param2                                           ; if found, proceed
                mov dx, format                                      ; else, select error message
                jmp error                                           ; proceed to error printing

param2:         push cx                                             ; save original cx
                mov si, 0x82                                        ; set si to start of param
                mov cx, di                                          ; set di to end of param
                sub cx, 0x82                                        ; find param size in cx
                dec cx                                              ; excluding the space
                mov di, filename1                                   ; set di to space for filename 1
                rep movsb                                           ; copy filename there
                mov byte [di], 0                                    ; terminate filename with 0

                pop cx                                              ; restore original cx
                inc si                                              ; go to start of next filename
                mov di, filename2                                   ; set di to space for filename 2
                rep movsb                                           ; copy filename there
                mov byte [di], 0                                    ; terminate filename with 0
                mov ah, 0x3d                                        ; service 3d – open file
                mov al, 0                                           ; readonly mode
                mov dx, filename1                                   ; address of filename
                int 0x21                                            ; dos services
                jnc open2                                           ; if no error, proceed
                mov dx, openfailed                                  ; else, select error message
                jmp error                                           ; proceed to error printing

open2:          mov [handle1], ax                                   ; save handle for first file
                mov ah, 0x3d                                        ; service 3d – open file
                mov al, 0                                           ; readonly mode
                mov dx, filename2                                   ; address of filename
                int 0x21                                            ; dos services
                jnc store2                                          ; if no error, proceed
                mov dx, openfailed2                                 ; else, select error message
                jmp error                                           ; proceed to error printing

store2:         mov [handle2], ax                                   ; save handle for second file

readloop:       mov ah, 0x3f                                        ; service 3f – read file
                mov bx, [handle1]                                   ; handle for file to read
                mov cx, 4096                                        ; number of bytes to read
                mov dx, buffer1                                     ; buffer to read in
                int 0x21                                            ; dos services
                jnc read2                                           ; if no error, proceed
                mov dx, readfailed                                  ; else, select error message
                jmp error                                           ; proceed to error printing

read2:          push ax                                             ; save number of bytes read
                mov ah, 0x3f                                        ; service 3f – read file
                mov bx, [handle2]                                   ; handle for file to read
                mov cx, 4096                                        ; number of bytes to read
                mov dx, buffer2                                     ; buffer to read in
                int 0x21                                            ; dos services
                jnc check                                           ; if no error, proceed
                mov dx, readfailed2                                 ; else, select error message
                jmp error                                           ; proceed to error printing

check:          pop cx                                              ; number of bytes read of file 1
                cmp ax, cx                                          ; are number of byte same
                je check2                                           ; yes, proceed to compare them
                mov dx, different                                   ; no, files are different
                jmp error                                           ; proceed to message printing

check2:         test ax, ax                                         ; are zero bytes read
                jnz compare                                         ; no, compare them
                mov dx, same                                        ; yes, files are same
                jmp error                                           ; proceed to message printing

compare:        mov si, buffer1                                     ; point si to file 1 buffer
                mov di, buffer2                                     ; point di to file 2 buffer
                repe cmpsb                                          ; compare the two buffers
                je check3                                           ; if equal, proceed
                mov dx, different                                   ; else, files are different
                jmp error                                           ; proceed to message printing

check3:         cmp ax, 4096                                        ; were 4096 bytes read
                je readloop                                         ; yes, try to read more
                mov dx, same                                        ; no, files are same

error:          mov ah, 9                                           ; service 9 – output message
                int 0x21                                            ; dos services

                mov ah, 0x3e                                        ; service 3e – close file
                mov bx, [handle1]                                   ; handle of file to close
                int 0x21                                            ; dos services
                
                mov ah, 0x3e                                        ; service 3e – close file
                mov bx, [handle2]                                   ; handle of file to close
                int 0x21                                            ; dos services

mov ax, 0x4c00                                                      ; terminate program
int 0x21