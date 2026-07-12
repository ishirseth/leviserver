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

load_file_table_s1:
    ; Load the 1st file table (Sector 10) into memory
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 11                ; File table is at sector 10 (offset of 1)
    mov dh, 0
    mov dl, 0x80
    mov bx, file_table_buffer_s1
    int 0x13
    ret

; INPUT: SI = address of filename string
; OUTPUT: AX = sector number, or 0 if not found
find_file_sector:
    mov bx, file_table_buffer_s1
.next_entry:
    cmp byte [bx], 0
    je .not_found
    
    push si
    mov di, bx
    mov cx, FILE_ENTRY_SIZE - 3
    repe cmpsb
    pop si
    je .found
    
    add bx, FILE_ENTRY_SIZE
    jmp .next_entry
.found:
    mov ax, [bx + FILE_ENTRY_SIZE - 3]   ; read full 2-byte sector value
    ret
.not_found:
    xor ax, ax                            ; clear the FULL register, not just al
    ret

; finds first empty sector in the filetable 
find_free_sector:
    mov bx, file_table_buffer_s1
    mov cx, 32                    ; scan all 32 entries
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

; ----- ERROR -----
error:
    mov si, err_msg
    call new_line
    call print
    mov al, 0 ; error flag
    ret