; LeviOS bootloader - minimal version

[org 0x7C00]        ; BIOS loads us here

start:
    mov si, msg     ; point to message

.print:
    lodsb           ; load byte from SI into AL
    or al, al       ; check if zero (end of string)
    jz load_kernel          ; if zero, stop printing

    mov ah, 0x0E    ; BIOS teletype output
    int 0x10        ; print AL to screen


    jmp .print

load_kernel:
     call delay_3sec

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0x80

    mov bx, 0x1000
    mov es, bx
    mov bx, 0x0000
    int 0x13

    call clear_screen

    ; --- jump to kernel ---
    push 0x1000
    push 0x0000
    retf

delay_3sec:
    mov cx, 0x002D      ; high 16 bits of 3,000,000 microseconds
    mov dx, 0xC6C0      ; low 16 bits of 3,000,000 microseconds
    mov ah, 0x86
    int 0x15
    ret

clear_screen:
    mov ah, 0x06        ; scroll up function
    mov al, 0x00        ; clear entire window (0 = clear all)
    mov bh, 0x07        ; white text on black background (attribute)
    mov cx, 0x0000       ; top-left corner (row 0, col 0)
    mov dx, 0x184F       ; bottom-right corner (row 24, col 79) - standard 80x25 screen
    int 0x10

    mov ah, 0x02        ; set cursor position
    mov bh, 0x00        ; page number (usually 0)
    mov dh, 0x00        ; row 0
    mov dl, 0x00        ; column 0
    int 0x10
    ret

msg:
    db " ", 0x0D,0x0A
    db "   |\---/|", 0x0D,0x0A
    db "   | ,_, |", 0x0D,0x0A
    db "    \_`_/-..----.", 0x0D,0x0A
    db " ___/ `   ' ,''+ \", 0x0D,0x0A
    db "(__...'   __\    |`.___.';", 0x0D,0x0A
    db "  (_,...'(_,.`__)/'.....+", 0x0D,0x0A
    db " ", 0x0D,0x0A
    db "LeviOS booted!", 0x0D,0x0A
    db "Loading system...", 0


times 510-($-$$) db 0  ; pad to 512 bytes
dw 0xAA55              ; boot signature