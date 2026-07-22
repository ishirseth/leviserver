; Made by Ishir Seth (myself)
; For my operating system LeviOS
; Pong
; esc to exit, w and s for paddle 1, i and k for paddle 2

PADDLE_SIZE equ 4      ; paddle size
PADDLE_STEP equ 2
SPEED equ 70            ; lower = faster

start:
    nop             ; SUPER IMPORTANT LOL

    mov ah, 0x01
    mov ch, 0x20    ; bit 5 set = cursor hidden
    mov cl, 0x00
    int 0x10

    call clear_screen
    call draw_border
    mov byte [ball_y], 10
    mov byte [ball_x], 40
    mov byte [ball_dy], 1
    mov byte [ball_dx], -1

    mov byte [paddle1_y], 10
    mov byte [paddle2_y], 10

main:
    call read_key
    jz .no_key            ; check if there is no key pressed

    cmp al, 0x1B          ; Escape?
    je .esc_pressed
    cmp al, 'w'         ; w?
    je .w_pressed
    cmp al, 's'         ; s?
    je .s_pressed
    cmp al, 'i'         ; i?
    je .i_pressed
    cmp al, 'k'         ; k?
    je .k_pressed
    .no_key:

    call update_paddles
    call check_collision
    call update_ball

    ;delay
    mov ax, SPEED
    mov cx, 1000 
    mul cx
    mov cx, dx      ; high 16 bits
    mov dx, ax      ; low 16 bits
    mov ah, 0x86
    int 0x15

    jmp main


.w_pressed:
    cmp byte [paddle1_y], 1
    jle .no_key
    mov cl, 32
    call print_paddles
    sub byte [paddle1_y], PADDLE_STEP
    jmp .no_key

.s_pressed:
    cmp byte [paddle1_y], 18
    jge .no_key
    mov cl, 32
    call print_paddles
    add byte [paddle1_y], PADDLE_STEP
    jmp .no_key

.i_pressed:
    cmp byte [paddle2_y], 1
    jle .no_key
    mov cl, 32
    call print_paddles
    sub byte [paddle2_y], PADDLE_STEP
    jmp .no_key

.k_pressed:
    cmp byte [paddle2_y], 18
    jge .no_key
    mov cl, 32
    call print_paddles
    add byte [paddle2_y], PADDLE_STEP
    jmp .no_key

.esc_pressed:
    ; clear, show cursor and then return to LeviOS
    call clear_screen

    mov ah, 0x01
    mov ch, 0x06     ; bit 5 is 0 (visible), start scan line 6
    mov cl, 0x07     ; end scan line 7
    int 0x10
    
    jmp 0x1000:0x0000   ; return to kernel LeviOS

read_key:
    mov ah, 0x01          ; Check if key is available
    int 0x16
    jz .no_key_waiting    ; If ZF=1, no key, skip out

    mov ah, 0x00          ; FIX: Read and remove the key from the buffer
    int 0x16
    ret
.no_key_waiting:
    ret



print_char:     ; dh (row/y max 24) dl (column/x max 79)
    mov ah, 0x02
    mov bh, 0x00
    int 0x10

    mov al, cl       ; character to print
    mov ah, 0x0E
    int 0x10
    ret

update_ball:
    mov dh, [ball_y]    
    mov dl, [ball_x]    
    mov cl, 32           ; clear ball character
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

print_paddles:
    mov bl, 0
    .paddle_loop1:
        inc bl
        mov dh, [paddle1_y]    ; get y pos in correct register
        add dh, bl
        mov dl, 3
        call print_char
        cmp bl, PADDLE_SIZE             ; paddle size of 3
        jne .paddle_loop1

    mov bl, 0
    .paddle_loop2:
        inc bl
        mov dh, [paddle2_y]    ; get y pos in correct register
        add dh, bl
        mov dl, 77
        call print_char
        cmp bl, PADDLE_SIZE             ; paddle size of 3
        jne .paddle_loop2
    ret

update_paddles:
    mov cl, 219           ; paddle character
    call print_paddles
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
    cmp byte [ball_x], 4
    je .left
    .left_ret:
    ret

    .bottom:
        mov byte [ball_dy], -1
        jmp .bottom_ret
    .right:
        ; paddle 2 collsion
        mov cl, [ball_y]
        mov dl, [paddle2_y]
        cmp cl, dl
        jle start
        add dl, PADDLE_SIZE
        cmp cl, dl
        jg start

        mov byte [ball_dx], -1
        jmp .right_ret

    .top:
        mov byte [ball_dy], 1
        jmp .top_ret
    .left:
        ; paddle 1 collsion
        mov cl, [ball_y]
        mov dl, [paddle1_y]
        cmp cl, dl
        jle start
        add dl, PADDLE_SIZE
        cmp cl, dl
        jg start
        
        mov byte [ball_dx], 1
        jmp .left_ret


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
ball_dy:  db 1     ; row velocity: +1 or -1 (0xFF)
ball_dx:  db 1     ; column velocity: +1 or -1 (0xFF)

paddle1_y: db 1
paddle2_y: db 1
