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

; --- FIND FILE SECTOR ---
; INPUT: SI = address of filename string (e.g., "levi.txt")
; OUTPUT: AL = sector number, or 0 if not found
find_file_sector:
    mov bx, file_table_buffer ; Buffer where we loaded sector 10
.next_entry:
    cmp byte [bx], 0
    je .not_found
    
    push si
    mov di, bx        ; DI = current table entry
    mov cx, FILE_ENTRY_SIZE - 3   ; name field size
    repe cmpsb
    pop si
    je .found
    
    add bx, FILE_ENTRY_SIZE
    jmp .next_entry

.found:
    mov al, [bx + FILE_ENTRY_SIZE - 3]   ; sector byte right after name
    ret
.not_found:
    xor al, al                ; Return 0 (no I/O here)
    ret