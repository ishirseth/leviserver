[org 0x0000]

start:
    mov ax, cs
    mov ds, ax
    mov es, ax

    mov di, command

    mov si, msg
    call print
    jmp main

main:
    call read_key       ; AL now holds the typed character
    call print_char
    jmp main

; ----- PRINT -----

print:
    lodsb
    or al, al
    jz .done

    mov ah, 0x0E
    int 0x10

    jmp print
.done:
    ret
print_char:
    mov ah, 0x0E
    int 0x10
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

; ----- INPUT -----

read_key:
    mov ah, 0x00
    int 0x16

    cmp al, 0x0D          ; Enter?
    je .enter_pressed
    cmp al, 0x08          ; Backspace?
    je .backspace
    cmp al, 0x20          ; Space?
    je .space_pressed
    
    ; Otherwise, store the char
    call .store_char
    ret

.space_pressed:
    cmp byte [space_pressed_flag], 1 ; Check if already switched
    je .return_from_space            ; If 1, ignore the space
    
    mov byte [space_pressed_flag], 1 ; Set flag to "switched"
    mov word [active_ptr], value     ; Switch to value buffer
    mov word [current_offset], 0     ; Reset offset
.return_from_space:
    ret
.enter_pressed:
    call parse_input
    call clear_input
    call new_line
    jmp main
.backspace:
    ret

.no_store:
    ret

.store_char:
    mov di, [active_ptr]      ; Load the address of the active buffer
    
    mov bx, [current_offset]
    mov [di + bx], al         ; Store character
    inc bx
    mov [current_offset], bx
    mov byte [di + bx], 0     ; Null terminate
    ret

; ------ CONVERT VALUE STRING TO NUMBER ------
str_to_num:
    mov si, value
    xor bx, bx

.loop:
    mov al, [si]
    cmp al, 0
    je .done

    sub al, '0'
    xor ah, ah

    push ax              ; save digit
    mov ax, bx           ; AX = current total
    mov cx, 10           ; use CX as multiplier, not BX
    mul cx               ; AX = AX * 10 (DX:AX, but DX=0 for small numbers)
    mov bx, ax           ; BX = new total
    pop ax               ; restore digit

    add bx, ax
    inc si
    jmp .loop

.done:
    ret


; ----- PROCESS INPUT -----

clear_input:
    mov di, command        ; Start at the beginning of the command buffer
    mov cx, 64             ; Total size of both buffers (32+32)
    xor al, al
    rep stosb              ; Efficiently clears the memory in one go
    
    ; Reset the state variables so we are ready for the next command
    mov word [active_ptr], command
    mov word [current_offset], 0
    mov byte [space_pressed_flag], 0
    
    ret                    ; Now it correctly returns here


parse_input:
    mov si, command
    mov di, levi_command
    call .compare_loop
    je .levi_function

    mov si, command
    mov di, echo_command
    call .compare_loop
    je .echo_function

    mov si, command
    mov di, readtxt_command
    call .compare_loop
    je .readtxt_function

    ret              ; Return if no match found (not_equal)
.compare_loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .done        ; Mismatch: ZF=0
    cmp al, 0        ; End of string: ZF=1
    je .done
    inc si
    inc di
    jmp .compare_loop
.done:
    ret

.levi_function:
    mov si, levi_str
    call new_line
    call print
    ret
.echo_function:
    call new_line
    mov al, '-'
    call print_char
    mov si, value
    call print
    ret

.readtxt_function:
    call str_to_num      ; convert to number
    add bx, 1           ; convert 0-indexed to BIOS 1-indexed

    ; print message stuff
    call new_line
    mov si, read_txt_str
    call print
    mov si, value
    call print
    mov al, ':'
    call print_char

    mov ax, ds           ; set ES = DS first, before touching AX for int 0x13
    mov es, ax

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, bl           ; sector number
    mov dh, 0
    mov dl, 0x80
    mov bx, txt_buffer
    int 0x13

    jc .txt_error

    mov si, txt_buffer
    call new_line
    call print
    ret
.txt_error:
    mov si, err_msg
    call new_line
    call print
    ret
.not_equal:
    ret

levi_command: db "levi", 0
echo_command: db "echo", 0
readtxt_command: db "readtxt", 0

levi_str: db "-Levi says hi!", 0
read_txt_str: db "-Reading ", 0
msg db "LeviOS is alive and doing stuff"
    db " ", 0x0D,0x0A, 0
err_msg:     db "Error!", 0

; --- State Variables ---
active_ptr:     dw command
current_offset: dw 0
space_pressed_flag: db 0

; --- Buffers ---
command:        times 32 db 0
value:          times 32 db 0
txt_buffer: times 512 db 0