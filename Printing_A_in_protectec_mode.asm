[org 0x0100]

jmp start

gdt:    dd 0x00000000, 0x00000000 ; null descriptor
        dd 0x0000FFFF, 0x00CF9A00 ; 32bit code
        ;    \--/\--/    \/||||\/
        ;     |   |      | ||||+--- Base (16..23)=0 fill later
        ;     |   |      | |||+--- X=1 C=0 R=1 A=0
        ;     |   |      | ||+--- P=1 DPL=00 S=1
        ;     |   |      | |+--- Limit (16..19) = F
        ;     |   |      | +--- G=1 D=1 r=0 AVL=0
        ;     |   |      +--- Base (24..31) = 0
        ;     |   +--- Limit (0..15) = FFFF
        ;     +--- Base (0..15)=0 fill later
        dd 0x0000FFFF, 0x00CF9200 ; data
        ;    \--/\--/    \/||||\/
        ;     |   |      | ||||+--- Base (16..23) = 0
        ;     |   |      | |||+--- X=0 E=0 W=1 A=0
        ;     |   |      | ||+--- P=1 DPL=00 S=1
        ;     |   |      | |+--- Limit (16..19) = F
        ;     |   |      | +--- G=1 B=1 r=0 AVL=0
        ;     |   |      +--- Base (24..31) = 0
        ;     |   +--- Limit (0..15) = FFFF
        ;     +--- Base (0..15) = 0

gdtreg: dw 0x17                             ; 16bit limit
        dd 0                                ; 32bit base (filled later)

stack:  times 256 dd 0                      ; for use in p-mode
stacktop:

start:  mov ax, 0x2401
        int 0x15                            ; enable A20

        xor eax, eax
        mov ax, cs
        shl eax, 4
        mov [gdt+0x08+2], ax
        shr eax, 16
        mov [gdt+0x08+4], al                ; fill base of code desc

        xor edx, edx
        mov dx, cs
        shl edx, 4
        add edx, stacktop                   ; edx = stack top for pmode

        xor eax, eax
        mov ax, cs
        shl eax, 4
        add eax, gdt
        mov [gdtreg+2], eax                 ; fill phy base of gdt
        lgdt [gdtreg]                       ; load gdtr

        mov eax, cr0
        or eax, 1

        cli                                 ; MUST disable interrupts
        mov cr0, eax                        ; P-MODE ON
        jmp 0x08:pstart                     ; load cs

;;;;; 32bit protected mode ;;;;;
[bits 32]                                   ; ask assembler to generate 32bit code
pstart: mov eax, 0x10
        mov ds, ax
        mov es, ax                          ; load other seg regs
        mov fs, ax                          ; flat memory model
        mov gs, ax
        mov ss, ax
        mov esp, edx
        
        mov byte [0x000b8000], 'A'          ; direct poke at video
        jmp $                               ; hang around