; a program to display the partition table
[org 0x0100]

jmp start

dap:        db 0x10, 0                          ; disk address packet
            dw 1
            dd 0, 0, 0

msg:        times 17 db ' '
            db 10, 13, '$'

fat12:      db 'FAT12...$'
fat16:      db 'FAT16...$'
fat32:      db 'FAT32...$'
ntfs:       db 'NTFS....$'
extended:   db 'EXTEND..$'
unknown:    db 'UNKNOWN.$'

partypes:   dw 0x1, fat12                       ; table of known partition types
            dw 0x5, extended
            dw 0x6, fat16
            dw 0xe, fat16
            dw 0xb, fat32
            dw 0xc, fat32
            dw 0x7, ntfs
            dw 0xf, extended
            dw 0x0, unknown

; subroutine to print a number in a string as hex
; takes address of string and a 16bit number as parameter
printnum:   push bp
            mov bp, sp
            push ax
            push bx
            push cx
            push dx
            push di

            mov di, [bp+6]                      ; string to store the number
            add di, 3

            mov ax, [bp+4]                      ; load number in ax
            mov bx, 16                          ; use base 16 for division
            mov cx, 4

nextdigit:  mov dx, 0
            div bx                              ; divide by 16
            add dl, 0x30                        ; convert into ascii value
            cmp dl, 0x39
            jbe skipalpha

            add dl, 7

skipalpha:  mov [di], dl                        ; update char in string
            dec di
            loop nextdigit

            pop di
            pop dx
            pop cx
            pop bx
            pop ax
            pop bp
            ret 4

; subroutine to print the start and end of a partition
; takes the segment and offset of the partition table entry
printpart:  push bp
            mov bp, sp
            push es
            push ax
            push di

            les di, [bp+4]                      ; point es:di to dap

            mov ax, msg
            push ax
            push word [es:di+0xA]
            call printnum                       ; print first half of start

            add ax, 4
            push ax
            push word [es:di+0x8]
            call printnum                       ; print second half of start

            add ax, 5
            push ax
            push word [es:di+0xE]
            call printnum                       ; print first half of end

            add ax, 4
            push ax
            push word [es:di+0xC]
            call printnum                       ; print second half of end

            mov dx, msg
            mov ah, 9
            int 0x21                            ; print the whole on the screen

            pop di
            pop ax
            pop es
            pop bp
            ret 4

; recursive subroutine to read the partition table
; take indentation level and 32bit absolute block number as parameters
readpart:   push bp
            mov bp, sp
            sub sp, 512                         ; local space to read sector
            push ax
            push bx
            push cx
            push dx
            push si

            mov ax, bp
            sub ax, 512
            mov word [dap+4], ax                ; init dest offset in dap
            mov [dap+6], ds                     ; init dest segment in dap
            mov ax, [bp+4]
            mov [dap+0x8], ax                   ; init sector no in dap
            mov ax, [bp+6]
            mov [dap+0xA], ax                   ; init second half of sector no

            mov ah, 0x42                        ; read sector in LBA mode
            mov dl, 0x80                        ; first hard disk
            mov si, dap                         ; address of dap
            int 0x13                            ; int 13

            jc failed                           ; if failed, leave

            mov si, -66                         ; start of partition info

nextpart:   mov ax, [bp+4]                      ; read relative sector number
            add [bp+si+0x8], ax                 ; make it absolute
            mov ax, [bp+6]                      ; read second half
            adc [bp+si+0xA], ax                 ; make seconf half absolute

            cmp byte [bp+si+4], 0               ; is partition unused
            je exit

            mov bx, partypes                    ; point to partition types
            mov di, 0

nextmatch:  mov ax, [bx+di]
            cmp [bp+si+4], al                   ; is this partition known
            je found                            ; yes, so print its name
            add di, 4                           ; no, try next entry in table
            cmp di, 32                          ; are all entries compared
            jne nextmatch                       ; no, try another

found:      mov cx, [bp+8]                      ; load indentation level
            jcxz noindent                       ; skip if no indentation needed

indent:     mov dl, ' '
            mov ah, 2                           ; display char service
            int 0x21                            ; dos services
            loop indent                         ; print required no of spaces

noindent:   add di, 2
            mov dx, [bx+di]                     ; point to partition type name
            mov ah, 9                           ; print string service
            int 0x21                            ; dos services
            
            push ss
            mov ax, bp
            add ax, si
            push ax                             ; pass partition entry address
            call printpart                      ; print start and end from it

            cmp byte [bp+si+4], 5               ; is it an extended partition
            je recurse                          ; yes, make a recursive call
            
            cmp byte [bp+si+4], 0xf             ; is it an extended partition
            jne exit                            ; yes, make a recursive call

recurse:    mov ax, [bp+8]
            add ax, 2                           ; increase indentation level
            push ax
            push word [bp+si+0xA]               ; push partition type address
            push word [bp+si+0x8]
            call readpart                       ; recursive call

exit:       add si, 16                          ; point to next partition entry
            cmp si, -2                          ; gone past last entry
            jne nextpart                        ; no, read this entry

failed:     pop si
            pop dx
            pop bx
            pop cx
            pop ax
            mov sp, bp
            pop bp
            ret 6

start:      xor ax, ax
            push ax                             ; start from zero indentation
            push ax                             ; main partition table at 0
            push ax
            call readpart                       ; read and print it

mov ax, 0x4c00                                  ; terminate program
int 0x21