; ram disk dos block device driver
header:     dd -1                                   ; no next driver
            dw 0x2000                               ; driver attributes: block device
            dw strategy                             ; offset of strategy routine
            dw interrupt                            ; offset of interrupt routine
            db 1                                    ; no of units supported
            times 7 db 0                            ; reserved

request:    dd 0                                    ; space for request header

ramdisk:    times 11 db 0                           ; initial part of boot sector
bpb:        dw 512                                  ; bytes per sector
            db 1                                    ; sectors per cluster
            dw 1                                    ; reserved sectors
            db 1                                    ; fat copies
            dw 48                                   ; root dir entries
            dw 105                                  ; total sectors
            db 0xf8                                 ; media desc byte: fixed disk
            dw 1                                    ; sectors per fat
            times 482 db 0                          ; remaining part of boot sector
            db 0xfe, 0xff, 0xff                     ; special bytes at start of FAT
            times 509 db 0                          ; remaining FAT entries unused
            times 103*512 db 0                      ; 103 sectors for data
bpbptr:     dw bpb                                  ; array of bpb pointers

dispatch:   dw init                                 ; command 0: init
            dw mediacheck                           ; command 1: media check
            dw getbpb                               ; command 2: get bpb
            dw unknown                              ; command 3: not handled
            dw input                                ; command 4: input
            dw unknown                              ; command 5: not handled
            dw unknown                              ; command 6: not handled
            dw unknown                              ; command 7: not handled
            dw output                               ; command 8: output
            dw output                               ; command 9: output with verify

; device driver strategy routine
strategy:   mov [cs:request], bx                    ; save request header offset
            mov [cs:request+2], es                  ; save request header segment
            retf

; device driver interrupt routine
interrupt:  push ax
            push bx
            push cx
            push dx
            push si
            push di
            push ds
            push es

            push cs
            pop ds

            les di, [request]
            mov word [es:di+3], 0x0100
            mov bl, [es:di+2]
            mov bh, 0
            cmp bx, 9
            ja skip
            shl bx, 1

            call [dispatch+bx]

skip:       pop es
            pop ds
            pop di
            pop si
            pop dx
            pop cx
            pop bx
            pop ax
            retf

mediacheck: mov byte [es:di+14], 1
            ret

getbpb:     mov word [es:di+18], bpb
            mov [es:di+20], ds
            ret

input:      mov ax, 512
            mul word [es:di+18]
            mov cx, ax

            mov ax, 512
            mul word [es:di+20]
            mov si, ax
            add si, ramdisk

            les di, [es:di+14]
            cld
            rep movsb
            ret

output:     mov ax, 512
            mul word [es:di+18]
            mov cx, ax

            lds si, [es:di+14]
            mov ax, 512
            mul word [es:di+20]
            mov di, ax
            add di, ramdisk

            push cs
            pop es
            cld
            rep movsb

unknown:    ret

init:       mov ah, 9
            mov dx, message
            int 0x21

            mov byte [es:di+13], 1
            mov word [es:di+14], init
            mov [es:di+16], ds
            mov word [es:di+18], bpbptr
            mov [es:di+20], ds
            ret

message:    db 13, 10, 'RAM Disk Driver loaded',13,10,'$'