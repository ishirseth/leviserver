
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
    call store_char
    ret

.space_pressed:
    cmp byte [space_pressed_flag], 1
    je .value
    
    mov byte [space_pressed_flag], 1
    mov bx, [current_offset]
    mov [command_offset], bx ; save command length
    mov word [current_offset], 0
.value:
    cmp [ignore_space_flag], 1
    je .ignore
    mov al, 0x20             ; Load space character
    call store_char         ; Save it to the buffer
    .ignore:

    mov byte [ignore_space_flag], 0
    mov word [active_ptr], value
    ret
.enter_pressed:
    call parse_input
    call clear_input
    call new_line
    jmp main
.backspace:
    mov bx, [current_offset]
    cmp bx, 0
    jne .do_backspace
    ; offset is 0 -- check if we're in value and can cross back to command
    cmp word [active_ptr], value
    jne .done                    ; already in command with offset 0, nothing to do

    mov word [active_ptr], command
    mov byte [space_pressed_flag], 0
    mov byte [ignore_space_flag], 1
    mov bx, [command_offset]
    mov [current_offset], bx
    ret

    .do_backspace:
        ; visual erase
        mov al, 0x08
        call print_char
        mov al, ' '
        call print_char
        mov al, 0x08
        call print_char
        call cursor_right

        dec bx
        mov [current_offset], bx
        mov di, [active_ptr]
        mov byte [di + bx], 0
    .done:
        ret

.no_store:
    ret

cursor_right:
    mov ah, 0x03
    mov bh, 0x00
    int 0x10          ; dh = row, dl = column

    inc dl
    mov ah, 0x02
    mov bh, 0x00
    int 0x10          ; set cursor to same row, column+1
    ret

store_char:
    mov di, [active_ptr]      ; di = current buffer address
    mov bx, [current_offset]  ; bx = current offset

    ; Check which buffer is active
    cmp di, command           ; Is this the command buffer?
    je .check_command
    
    cmp di, value             ; Is this the value buffer?
    je .check_value
    
    jmp .store                ; Fallback/Error handling
    .check_command:               ; Check if input is too long
        cmp bx, 31                ; Max 31 chars + 1 null = 32
        jae .done                 
        jmp .store
    .check_value:
        cmp bx, 511               ; Max 511 chars
        jae .done                 
    .store:
        mov [di + bx], al         ; Store character
        inc bx
        mov [current_offset], bx
        mov byte [di + bx], 0     ; Null terminate
    .done:
        ret



; ----- PROCESS INPUT -----

clear_input:
    mov di, command        ; Start at the beginning of the command buffer
    mov cx, 160             ; Total size of both buffers (32+128)
    xor al, al
    rep stosb              ; Efficiently clears the memory in one go
    
    ; Reset the state variables so we are ready for the next command
    mov word [active_ptr], command
    mov word [current_offset], 0
    mov byte [space_pressed_flag], 0
    mov byte [ignore_space_flag], 1
    ret

parse_input:
    mov si, command
    mov di, levi_command
    call .compare_loop
    je levi_function

    mov si, command
    mov di, echo_command
    call .compare_loop
    je echo_function

    mov si, command
    mov di, readtxt_command
    call .compare_loop
    je readtxt_function

    mov si, command
    mov di, write_command
    call .compare_loop
    je write_function

    mov si, command
    mov di, write_data_command
    call .compare_loop
    je write_data_function

    mov si, command
    mov di, delete_command
    call .compare_loop
    je delete_function

    mov si, command
    mov di, ls_command
    call .compare_loop
    je ls_function

    mov si, command
    mov di, sl_command
    call .compare_loop
    je sl_function

    mov si, command
    mov di, clear_command
    call .compare_loop
    je clear_function

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



