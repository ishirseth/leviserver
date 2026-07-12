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

; ------ CONVERT INT AND STR ------
; si = input string - bx = int 
; max: 65,535
str_to_num:
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

; bx = int si = string
; max: 65,535
num_to_str:
    push bx
    push si
    mov ax, bx ; divisor
    xor bx, bx
    xor dx, dx
.loop:
    cmp ax, 0 ; finish when quotient is 0
    je .reverse
    mov cx, 10 ; divides to get remainder 
    div cx
    add dx, '0' ; makes remainder a char
    push dx
    xor dx, dx ; clear remainder
    inc bl
    jmp .loop
.reverse:
    cmp bl, 0
    je .done
    pop dx
    mov [si], dl
    inc si
    dec bl
    jmp .reverse
.done:
    mov byte [si], 0  ; add the null termiantor at the end
    pop si
    pop bx
    ret

; --- FILE SYS ---

load_file_table:
    mov ah, 0x02
    mov al, 2              ; load 2 sectors (1024 bytes) instead of 1
    mov ch, 0
    mov cl, 11             ; start at sector 10 (BIOS 1-indexed = 11)
    mov dh, 0
    mov dl, 0x80
    mov bx, file_table_buffer
    int 0x13
    ret
write_file_table:
    ; write both tables back to disk (sectors 10-11)
    push ax
    mov ah, 0x03
    mov al, 2              ; write 2 sectors (both tables)
    mov ch, 0
    mov cl, 11             ; start at sector 10 (BIOS 1-indexed = 11)
    mov dh, 0
    mov dl, 0x80
    mov bx, file_table_buffer
    int 0x13
    pop ax
    ret

; txt_buffer = text and bl = sector
write_sector:
    add bx, 1
    mov ah, 0x00     ; reset disk
    mov dl, 0x80
    int 0x13

    mov ax, 0x0301          ; AH=03h (Write), AL=01h (1 sector)
    mov ch, 0               ; Cylinder 0
    mov cl, bl              ; Sector 
    mov dh, 0               ; Head 0
    mov dl, 0x80            ; Drive 0x80
    push ds
    pop es
    mov bx, txt_buffer      ; Buffer offset
    int 0x13                ; Call BIOS
    jnc .done            ; If no carry, success!

    call error     ; error
    ret
.done:
    ret
; txt_buffer = text and bl = sector
read_sector:
    add bx, 1
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, bl           ; sector number 
    mov dh, 0
    mov dl, 0x80
    mov bx, txt_buffer
    int 0x13
    jc error
    ret

; INPUT: SI = address of filename string
; OUTPUT: AX = sector number, or 0 if not found
find_file_sector:
    mov bx, file_table_buffer
    mov dx, 64                    ; scan all 64 entries
.next_entry:
    cmp byte [bx], 0
    je .skip                      ; empty entry? skip it, don't stop
    
    push si
    mov di, bx
    mov cx, FILE_ENTRY_SIZE - 3
    repe cmpsb
    pop si
    je .found
.skip:
    add bx, FILE_ENTRY_SIZE
    dec dx
    jnz .next_entry
    xor ax, ax                    ; scanned everything, not found
    ret
.found:
    mov ax, [bx + FILE_ENTRY_SIZE - 3]
    ret

; finds first empty sector in the filetable 
find_free_sector:
    mov bx, file_table_buffer
    mov cx, 64                    ; scan all 64 entries
.check_entry:
    cmp byte [bx], 0               ; empty entry = name field starts with 0
    je .found
    add bx, FILE_ENTRY_SIZE
    loop .check_entry
    xor ax, ax                    ; no free entry found
    ret
.found:
    mov ax, [bx + FILE_ENTRY_SIZE - 3]   ; sector byte, pre-filled by the Makefile
    ret

; check if value is not too long and exists
; ax = max length
check_value:
    ; check if it exists
    cmp byte [value], 0
    je error
    cmp byte [value], 0x20 ; space
    je error

    ; check length
    mov si, value
    xor cx, cx
    .count_loop:
        cmp byte [si], 0
        je .count_done
        inc cx
        inc si
        cmp cx, ax ; check length ax = max
        ja error
        jmp .count_loop
    .count_done:
    mov ax, 1 ; pass flag
    ret

; ----- MEMORY -----
; di = destination
; si = source
mov_index_data:
    lodsb           ; Load [SI] into AL, inc SI
    stosb           ; Store AL into [DI], inc DI
    test al, al     ; Check if 0 (null terminator)
    jnz mov_index_data       ; Continue until 0 is copied
    ret

; ----- ERROR -----
error:
    mov si, err_msg
    call new_line
    call print
    mov al, 0 ; error flag
    ret
