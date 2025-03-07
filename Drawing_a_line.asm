; draw line in graphics mode
[org 0x0100]

        mov ax, 0x000D ; set 320x200 graphics mode
        int 0x10 ; bios video services

        mov ax, 0x0C07 ; put pixel in white color
        xor bx, bx ; page number 0
        mov cx, 200 ; x position 200
        mov dx, 200 ; y position 200

l1:     int 0x10 ; bios video services
        dec dx ; decrease y position
        loop l1 ; decrease x position and repeat

        mov ah, 0 ; service 0 – get keystroke
        int 0x16 ; bios keyboard services

        mov ax, 0x0003 ; 80x25 text mode
        int 0x10 ; bios video services

mov ax, 0x4c00 ; terminate program
int 0x21