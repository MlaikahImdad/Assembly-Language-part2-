[org 0x0100]

jmp start

modeblock:      times 256 db 0

gdt:            dd 0x00000000, 0x00000000   ; null descriptor
                dd 0x0000FFFF, 0x00CF9A00   ; 32bit code
                dd 0x0000FFFF, 0x00CF9200   ; data

gdtreg:         dw 0x17                     ; 16bit limit
                dd 0                        ; 32bit base

stack:          times 256 dd 0              ; 1K stack
stacktop:

start:          mov ax, 0x4f01              ; get vesa mode information
                mov cx, 0x4117              ; 1024*768*64K linear frame
buffer
                mov di, modeblock
                int 0x10
                mov esi, [modeblock+0x28]   ; save frame buffer base

                mov ax, 0x4f02              ; set vesa mode
                mov bx, 0x4117
                int 0x10

                mov ax, 0x2401
                int 0x15                    ; enable a20

                xor eax, eax
                mov ax, cs
                shl eax, 4
                mov [gdt+0x08+2], ax
                shr eax, 16
                mov [gdt+0x08+4], al        ; set base of code desc

                xor edx, edx
                mov dx, cs
                shl edx, 4
                add edx, stacktop           ; stacktop to be used in p-mode

                xor eax, eax
                mov ax, cs
                shl eax, 4
                add eax, gdt
                mov [gdtreg+2], eax         ; set base of gdt
                lgdt [gdtreg]               ; load gdtr

                mov eax, cr0
                or eax, 1

                cli                         ; disable interrupts
                mov cr0, eax                ; enable protected mode
                jmp 0x08:pstart             ; load cs

;;;;; 32bit protected mode ;;;;;

[bits 32]
pstart:         mov ax, 0x10                ; load all seg regs to 0x10
                mov ds, ax                  ; flat memory model
                mov es, ax
                mov fs, ax
                mov gs, ax
                mov ss, ax
                mov esp, edx                ; load saved esp on stack

l1:             xor eax, eax
                mov edi, esi
                mov ecx, 1024*768*2/4       ; divide by 4 as dwords
                cld
                rep stosd

                mov eax, 0x07FF07FF
                mov ecx, 32                 ; no of bands
                mov edi, esi

l2:             push ecx
                mov ecx, 768*16             ; band width = 32
lines
                cld
                rep stosd

                mov ecx, 0x000FFFFF         ; small wait
                loop $
                pop ecx

                sub eax, 0x00410041
                loop l2

                mov ecx, 0x0FFFFFFF         ; long wait
                loop $
                jmp l1