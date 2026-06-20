[org 0x0000]

start:
    mov ax, cs
    mov ds, ax

    mov di, command

    mov si, msg
    call print
    jmp main

main:
    call read_key       ; AL now holds the typed character
    cmp al, 0x0D        ; is it Enter (carriage return)?
    je enter_pressed

    call print_char
    jmp main

print:
    lodsb
    or al, al
    jz .done

    mov ah, 0x0E
    int 0x10

    jmp print
.done:
    ret

new_line:
    mov ah, 0x03        ; get current cursor position
    mov bh, 0x00
    int 0x10             ; row -> DH, column -> DL (ignored)

    inc dh               ; move to next row
    mov dl, 0x00          ; column 0

    mov ah, 0x02        ; set cursor position
    mov bh, 0x00
    int 0x10
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

read_key:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D
    je .no_store
    call store_char
.no_store:
    ret

store_char:
    mov [di], al
    inc di
    mov byte [di], 0
    ret

enter_pressed:
    call check_test
    call clear_command
    call new_line
    jmp main

clear_command:
    mov di, command
    mov cx, 64
    xor al, al
.clear_loop:
    mov [di], al
    inc di
    loop .clear_loop

    mov di, command
    ret

check_test:
    mov si, command
    mov di, test_command

.compare_loop:
    mov al, [si]
    mov bl, [di]

    cmp al, bl
    jne .not_equal

    cmp al, 0          ; if both are 0, we've reached the end of both strings - match!
    je .equal

    inc si
    inc di
    jmp .compare_loop

.equal:
    mov si, test_str
    call new_line
    call print
    ret

.not_equal:
    mov si, command
    mov al, "-"
    call new_line
    call print_char
    call print
    ret

test_command: db "levi", 0
test_str: db "-Levi says hi!", 0
msg db "LeviOS is alive and doing stuff"
    db " ", 0x0D,0x0A, 0
command: times 64 db 0