; ----- COMMANDS -----

levi_function:
    mov si, levi_str
    call new_line
    call print
    ret

echo_function:
    call new_line
    mov al, '-'
    call print_char
    mov si, value
    call print
    ret

readtxt_function:
    call load_file_table_s1

    ; Search for the filename (which is in 'value' buffer)
    mov si, value             ; The filename the user typed
    call find_file_sector
    cmp ax, 0                 ; Did we find it?
    je error             ; If AL=0, not found
    mov bx, ax

    ; print message stuff
    call new_line
    mov si, read_str1
    call print
    mov si, value
    call print
    mov si, read_str2
    call print
    mov si, num_buffer
    call num_to_str
    call print
    mov al, ':'
    call print_char

    mov ax, ds           ; set ES = DS first, before touching AX for int 0x13
    mov es, ax

    call read_sector

    mov si, txt_buffer
    call new_line
    call print
    ret
.not_equal:
    ret

write_function:
    call load_file_table_s1

    mov ax, FILE_ENTRY_SIZE - 3
    call check_value
    cmp al, 0                 ; check_value returns 0 = fail, 1 = ok
    je .done

    ; --- Check filename doesn't already exist ---
    mov si, value
    call find_file_sector
    cmp ax, 0
    jne .skip_entry              ; if a sector was returned file already exists

    call find_free_sector       ; AL = sector number, BX = entry address
    ; write new entry into the buffer 
    push ax
    mov si, value
    mov di, bx
    mov cx, FILE_ENTRY_SIZE - 3
    rep movsb
    pop ax
    mov [bx + FILE_ENTRY_SIZE - 3], ax
    call write_file_table

    .skip_entry:  ; entry already created

    push ax
    mov word [write_sector_buffer], ax
    mov di, write_file_buffer ; destination
    mov si, value      ; source
    call mov_index_data
    pop ax

    push ax
    call new_line
    mov si, write_str
    call print
    mov si, value
    call print
    mov si, read_str2
    call print
    pop ax
    mov bx, ax
    mov si, num_buffer
    call num_to_str
    call print
    ret
.done:
    ret

write_data_function:
    mov ax, [write_sector_buffer]
    mov bx, ax

    call new_line
    mov si, write_data_str
    call print
    mov si, write_file_buffer
    call print
    mov si, read_str2
    call print

    mov si, num_buffer
    call num_to_str
    call print

    mov di, txt_buffer ; destination
    mov si, value      ; source
    call mov_index_data
    
    call write_sector
    ret

ls_function:
    call load_file_table_s1
    mov bx, file_table_buffer_s1
    mov cx, 32                  ; scan all 32 entries
.next_entry:
    cmp byte [bx], 0            ; empty entry?
    je .skip                    ; skip it (don't print blank entries)
    push cx

    push bx
    mov si, bx
    call new_line
    call print
    pop bx
    push bx
    mov word bx, [bx + FILE_ENTRY_SIZE - 3]
    call num_to_str
    mov al, ' '
    call print_char
    call print
    pop bx

    pop cx
.skip:
    add bx, FILE_ENTRY_SIZE
    loop .next_entry
    ret