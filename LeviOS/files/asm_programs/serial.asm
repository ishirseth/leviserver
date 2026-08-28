; Made by Ishir Seth (myself)
; For my operating system LeviOS
; Serial

org 0x2000

mov al, 's'
mov ah, 0x0E
int 0x10

.esc_pressed:
    call clear_screen
    jmp 0x1000:0x0000   ; return to kernel LeviOS


clear_screen:
    mov ah, 0x06        
    mov al, 0x00   
    mov bh, 0x07   
    mov cx, 0x0000      
    mov dx, 0x184F      
    int 0x10

    mov ah, 0x02   
    mov bh, 0x00
    mov dh, 0x00
    mov dl, 0x00
    int 0x10
    ret