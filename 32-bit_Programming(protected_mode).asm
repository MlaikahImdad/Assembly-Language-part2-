[org 0x0100]

jmp start

gdt:        dd 0x00000000, 0x00000000 ; null descriptor
            dd 0x0000FFFF, 0x00CF9A00 ; 32bit code
            dd 0x0000FFFF, 0x00CF9200 ; data

gdtreg:     dw 0x17                   ; 16bit limit
            dd 0                      ; 32bit base

rstring:    db 'In Real Mode...', 0
pstring:    db 'In Protected Mode...', 0

stack:      times 256 dd 0            ; 1K stack
stacktop:

printstr:   push bp                   ; real mode print string
            mov bp, sp
            push ax
            push cx
            push si
            push di
            push es

            mov di,[bp+4]             ;load string address
            mov cx,0xffff             ;load maximum possible size in cx
            xor al,al                 ;clear al reg
            repne scasb               ;repeat scan
            mov ax,0xffff ;
            sub ax,cx                 ;calculate length
            dec ax                    ;off by one, as it includes zero
            mov cx,ax                 ;move length to counter

            mov ax, 0xb800
            mov es, ax                ; point es to video base
            mov ax,80                 ;its a word move, clears ah
            mul byte [bp+8]           ;its a byte mul to calc y offset
            add ax,[bp+10]            ;add x offset
            shl ax,1                  ;mul by 2 to get word offset
            mov di,ax                 ;load pointer

            mov si, [bp+4]            ; string to be printed
            mov ah, [bp+6]            ; load attribute
            cld                       ; set auto increment mode

nextchar:   lodsb                     ;load next char and inc si by 1
            stosw                     ;store ax and inc di by 2
            loop nextchar

            pop es
            pop di
            pop si
            pop cx
            pop ax
            pop bp
            ret 8

start:      push byte 0               ; 386 can directly push
immediates

            push byte 10
            push byte 7
            push word rstring
            call printstr

            mov ax, 0x2401
            int 0x15                  ; enable a20

            xor eax, eax
            mov ax, cs
            shl eax, 4
            mov [gdt+0x08+2], ax
            shr eax, 16
            mov [gdt+0x08+4], al      ; set base of code desc

            xor edx, edx
            mov dx, cs
            shl edx, 4
            add edx, stacktop         ; stacktop to be used in p-mode

            xor ebx, ebx
            mov bx, cs
            shl ebx, 4
            add ebx, pstring          ; pstring to be used in p-mode

            xor eax, eax
            mov ax, cs
            shl eax, 4
            add eax, gdt
            mov [gdtreg+2], eax       ; set base of gdt
            lgdt [gdtreg]             ; load gdtr

            mov eax, cr0
            or eax, 1

            cli                       ; disable interrupts
            mov cr0, eax              ; enable protected mode
            jmp 0x08:pstart           ; load cs

;;;;; 32bit protected mode ;;;;;
[bits 32]
pprintstr:  push ebp                  ; p-mode print string routine
            mov ebp, esp
            push eax
            push ecx
            push esi
            push edi

            mov edi, [ebp+8]          ;load string address
            mov ecx, 0xffffffff       ;load maximum possible size in cx
            xor al, al                ;clear al reg
            repne scasb               ;repeat scan
            mov eax, 0xffffffff 
            sub eax, ecx              ;calculate length
            dec eax                   ;off by one, as it includes zero
            mov ecx, eax              ;move length to counter

            mov eax, 80               ;its a word move, clears ah
            mul byte [ebp+16]         ;its a byte mul to calc y
offset
            add eax, [ebp+20]         ;add x offset
            shl eax, 1                ;mul by 2 to get word offset
            add eax, 0xb8000
            mov edi, eax              ;load pointer

            mov esi, [ebp+8]          ; string to be printed
            mov ah, [ebp+12]          ; load attribute

            cld                       ; set auto increment mode

pnextchar:  lodsb                     ;load next char and inc si by 1
            stosw                     ;store ax and inc di by 2
            loop pnextchar

            pop edi
            pop esi
            pop ecx
            pop eax
            pop ebp
            ret 16                    ; 4 args now mean 16 bytes

pstart:     mov ax, 0x10              ; load all seg regs to 0x10
            mov ds, ax                ; flat memory model
            mov es, ax
            mov fs, ax
            mov gs, ax
            mov ss, ax
            mov esp, edx              ; load saved esp on stack
            
            push byte 0
            push byte 11
            push byte 7
            push ebx
            call pprintstr            ; call p-mode print string
routine
            mov eax, 0x000b8000
            mov ebx, '/-\|'

nextsymbol: mov [eax], bl
            mov ecx, 0x00FFFFFF
            loop $
            ror ebx, 8
            jmp nextsymbol