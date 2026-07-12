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
    mov si, read_txt_str1
    call print
    mov si, value
    call print
    mov si, read_txt_str2
    call print

    mov si, num_buffer
    call num_to_str
    call print
    mov al, ':'
    call print_char

    mov ax, ds           ; set ES = DS first, before touching AX for int 0x13
    mov es, ax

    add bx, 1           ; convert 0-indexed to BIOS 1-indexed

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, bl           ; sector number 
    mov dh, 0
    mov dl, 0x80
    mov bx, txt_buffer
    int 0x13

    jc error

    mov si, txt_buffer
    call new_line
    call print
    ret

.not_equal:
    ret

writetxt_function:
    call load_file_table_s1

    mov ax, FILE_ENTRY_SIZE - 3
    call check_value
    cmp al, 0                 ; check_value returns 0 = fail, 1 = ok
    je .done

    ; --- Check filename doesn't already exist ---
    mov si, value
    call find_file_sector
    cmp ax, 0
    jne error              ; if a sector was returned file already exists

    call find_free_sector       ; AL = sector number, BX = entry address

    ; write new entry into the buffer 
    push ax
    mov si, value
    mov di, bx
    mov cx, FILE_ENTRY_SIZE - 3
    rep movsb
    pop ax
    mov [bx + FILE_ENTRY_SIZE - 3], ax

    ; write updated table back to disk (sector 10)
    push ax
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, 11
    mov dh, 0
    mov dl, 0x80
    mov bx, file_table_buffer_s1
    int 0x13
    pop ax

    push ax
    call new_line
    mov si, write_txt_str
    call print
    mov si, value
    call print
    mov si, read_txt_str2
    call print
    pop ax
    mov bx, ax
    mov si, num_buffer
    call num_to_str
    call print
    mov al, ':'
    call print_char
    ret
.done:
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