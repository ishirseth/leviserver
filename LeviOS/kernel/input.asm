
; ----- INPUT -----

read_key:
    mov ah, 0x00
    int 0x16

    cmp al, 0x0D      
    je .enter_pressed
    cmp al, 0x1B    
    je .enter_pressed 
    cmp al, 0x08         
    je .backspace
    cmp al, 0x20         
    je .space_pressed
    
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
    cmp byte [ignore_space_flag], 1
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
    mov di, [active_ptr]      
    mov bx, [current_offset]  
    
    cmp di, command           
    je .check_command
    
    cmp di, value            
    je .check_value
    
    jmp .store             
    .check_command:             
        cmp bx, 31             
        jae .done                 
        jmp .store
    .check_value:
        cmp bx, 1599            
        jae .done                 
    .store:
        mov [di + bx], al        
        inc bx
        mov [current_offset], bx
        mov byte [di + bx], 0   
    .done:
        ret



; ----- PROCESS INPUT -----

clear_input:
    mov di, command       
    mov cx, 160          
    xor al, al
    rep stosb              
    
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
    mov di, read_command
    call .compare_loop
    je read_function

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

    mov si, command
    mov di, run_command
    call .compare_loop
    je run_function

    mov si, command
    mov di, help_command
    call .compare_loop
    je help_function


    ret               
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



