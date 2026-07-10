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
    ; Load the file table (Sector 10) into memory
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 11                ; File table is at sector 10 (offset of 1)
    mov dh, 0
    mov dl, 0x80
    mov bx, file_table_buffer
    int 0x13

    ; Search for the filename (which is in 'value' buffer)
    mov si, value             ; The filename the user typed
    call find_file_sector
    cmp al, 0                 ; Did we find it?
    je .txt_error             ; If AL=0, not found

    mov bl, al
    add bl, 1           ; convert 0-indexed to BIOS 1-indexed

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