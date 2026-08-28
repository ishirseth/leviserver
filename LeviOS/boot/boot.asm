; LeviOS bootloader

[org 0x7C00]      

start:
    cli            
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ss, ax       
    mov sp, 0xFFFF  
    
    sti
    
    mov [boot_drive], dl
    mov [ds:0x0500], dl
    mov si, msg

.print:
    lodsb         
    or al, al      
    jz load_kernel          

    mov ah, 0x0E    
    int 0x10       


    jmp .print

load_kernel:
    call delay_3sec

    mov ah, 0x02
    mov al, 9        ; read 9 sectors
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]

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
    mov cx, 0x002D      
    mov dx, 0xC6C0      
    mov ah, 0x86
    int 0x15
    ret

clear_screen:
    mov ah, 0x06    
    mov al, 0x00       
    mov bh, 0x07     
    mov cx, 0x0000   
    mov dx, 0x184F      
    int 0x10

    mov ah, 0x02        
    mov bh, 0x00      
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

times 509-($-$$) db 0  ; pad to 512 bytes
boot_drive: db 0x80      
dw 0xAA55              ; boot signature