; Made by Ishir Seth (myself)
; For my operating system LeviOS
; Serial

org 0x2000

start:
    mov ah, 00h
    mov al, 11100011b   ; 9600 baud
    xor dx, dx
    int 14h

main:
call read_key   
call read_serial
jmp main

print_char:
    mov ah, 0x0E
    int 0x10
    ret


read_serial:
    mov ah, 0x03     
    xor dx, dx
    int 14h
    test ah, 0x01 
    jz .no_data
    mov ah, 0x02   
    xor dx, dx
    int 14h
    mov ah, 0x0E
    int 0x10

    cmp al, 0x0A
    je .cursor
    cmp al, 0x0D
    je .cursor
    jmp .no_data

    .cursor:
        mov al, 0x0D
        mov ah, 0x0E
        int 0x10
    .no_data:
        ret

write_serial:
    mov ah, 01h
    mov al, al
    xor dx, dx
    int 14h
    ret

read_key:
    mov ah, 0x01
    int 0x16
    jz .no_key           
    mov ah, 0x00
    int 0x16              
    cmp al, 0x1B          
    je .esc_pressed
    call write_serial

    cmp al, 0x0D
    je .enter_pressed
    .no_key:
        ret


.enter_pressed:
    mov ah, 0x03
    mov bh, 0x00
    int 0x10          

    cmp dh, 24
    jl .increment

    push ax
    mov ah, 0x06        
    mov al, 1            
    mov bh, 0x07         
    mov cx, 0x0000      
    mov dx, 0x184F       
    int 0x10
    pop ax
    mov dh, 24          
    jmp .set_cursor
    .increment:
        inc dh
    .set_cursor:
        mov dl, 0x00

        mov ah, 0x02
        mov bh, 0x00
        int 0x10
        ret

.esc_pressed:
    ; clear, show cursor and then return to LeviOS
    call clear_screen

    mov ah, 0x01
    mov ch, 0x06  
    mov cl, 0x07 
    int 0x10
    
    jmp 0x1000:0x0000

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


send_msg: times 32 db 0
current_offset: times 2 db 0