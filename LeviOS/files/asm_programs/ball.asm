; Made by Ishir Seth (myself)
; For my operating system LeviOS
; Ball


start:
    mov ah, 0x01
    mov ch, 0x20    ; bit 5 set = cursor hidden
    mov cl, 0x00
    int 0x10

    call draw_border
    mov byte [ball_y], 10
    mov byte [ball_x], 40
    mov byte [ball_dy], 1
    mov byte [ball_dx], -1

main:
    call read_key
    jz .no_key            ; check if there is no key pressed
    cmp al, 0x1B          ; Escape?
    je .esc_pressed
    .no_key:

    call check_collision
    call update_ball

    ;delay
    mov ax, 50
    call delay

    jmp main

.esc_pressed:
    ; clear, show cursor and then return to LeviOS
    call clear_screen
    mov ah, 0x01
    mov ch, 0x06     ; bit 5 is 0 (visible), start scan line 6
    mov cl, 0x07     ; end scan line 7
    int 0x10
    
    push 0x1000
    push 0x0000
    retf 

read_key:
    mov ah, 0x01
    int 0x16
    ret

print_char:     ; dh (row/y max 24) dl (column/x max 79)
    mov ah, 0x02
    mov bh, 0x00
    int 0x10

    mov al, cl       ; character to print (ball)
    mov ah, 0x0E
    int 0x10
    ret

update_ball:
    mov dh, [ball_y]    
    mov dl, [ball_x]    
    mov cl, 32           ; clear ball
    call print_char

    ; update ball postion using ball velocity
    mov ah, [ball_y]
    mov al, [ball_x]
    add ah, [ball_dy]
    add al, [ball_dx]
    add al, [ball_dx]
    mov [ball_y], ah
    mov [ball_x], al

    mov dh, [ball_y]    ; get y pos in correct register
    mov dl, [ball_x]    ; get x pos in correct register
    mov cl, 4           ; ball character
    call print_char
    ret

check_collision:
    cmp byte [ball_y], 22
    je .bottom
    .bottom_ret:
    cmp byte [ball_x], 76
    je .right
    .right_ret:
    cmp byte [ball_y], 1
    je .top
    .top_ret:
    cmp byte [ball_x], 2
    je .left
    .left_ret:
    ret

    .bottom:
        mov byte [ball_dy], -1
        jmp .bottom_ret
    .right:
        mov byte [ball_dx], -1
        jmp .right_ret
    .top:
        mov byte [ball_dy], 1
        jmp .top_ret
    .left:
        mov byte [ball_dx], 1
        jmp .left_ret

delay:              ; ax = time in ms
    push ax         ; preserve ax
    mov cx, 1000 
    mul cx

    mov cx, dx      ; high 16 bits
    mov dx, ax      ; low 16 bits
    mov ah, 0x86
    int 0x15
    pop ax
    ret

draw_border:
    push cx
    mov cl, 177          ; border character

    ; top row (row 0, all columns 0-79)
    mov dh, 0
    xor dl, dl
    .top_loop:
        call print_char
        inc dl
        cmp dl, 80
        jne .top_loop

        ; bottom row (row 24, all columns 0-79)
        mov dh, 23
        xor dl, dl
    .bottom_loop:
        call print_char
        inc dl
        cmp dl, 80
        jne .bottom_loop

        ; left column (column 0, all rows 0-24)
        mov dl, 0
        xor dh, dh
    .left_loop:
        call print_char
        inc dh
        cmp dh, 24
        jne .left_loop

        ; right column (column 79, all rows 0-24)
        mov dl, 79
        xor dh, dh
    .right_loop:
        call print_char
        inc dh
        cmp dh, 24
        jne .right_loop

        pop cx
        ret

clear_screen:
    mov ah, 0x06        ; scroll up function
    mov al, 0x00        ; clear entire window (0 = clear all)
    mov bh, 0x07        ; white text on black background (attribute)
    mov cx, 0x0000       ; top-left corner (row 0, col 0)
    mov dx, 0x184F       ; bottom-right corner (row 24, col 79)
    int 0x10

    mov ah, 0x02        ; set cursor position
    mov bh, 0x00
    mov dh, 0x00
    mov dl, 0x00
    int 0x10
    ret


ball_y: db 1
ball_x: db 1
ball_old_y: db 1
ball_old_x: db 1
ball_dy:  db 1     ; row velocity: +1 or -1 (0xFF)
ball_dx:  db 1     ; column velocity: +1 or -1 (0xFF)