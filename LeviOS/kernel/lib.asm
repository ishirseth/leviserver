; ----- DISPLAY -----

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
    mov ah, 0x03
    mov bh, 0x00
    int 0x10          

    cmp dh, 24
    jl .increment

    push ax
    mov ah, 0x06        
    mov al, 1            
    mov bh, 0x07         
    mov cx, 0x0000      
    mov dx, 0x184F       
    int 0x10
    pop ax
    mov dh, 24           ; stay on last row after scrolling
    jmp .set_cursor
    .increment:
        inc dh
    .set_cursor:
        mov dl, 0x00

        mov ah, 0x02
        mov bh, 0x00
        int 0x10
        ret
clear_screen:
    mov ah, 0x06        
    mov al, 0x00        
    mov bh, 0x07        
    mov cx, 0x0000      
    mov dx, 0x184F       
    int 0x10

    mov ah, 0x02        ; set cursor position
    mov bh, 0x00
    mov dh, 0x00
    mov dl, 0x00
    int 0x10
    ret

; ------ CONVERT ------
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

        push ax             
        mov ax, bx       
        mov cx, 10          
        mul cx          
        mov bx, ax          
        pop ax            

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
    mov ax, bx
    xor bx, bx
    xor dx, dx

    cmp ax, 0
    jne .loop
    mov byte [si], '0'
    inc si
    jmp .done
    .loop:
        cmp ax, 0 
        je .reverse
        mov cx, 10
        div cx
        add dx, '0' 
        push dx
        xor dx, dx 
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
        mov byte [si], 0  ; add the null termiantor
        pop si
        pop bx
        ret


    push ax
    push bx
    push dx

    mov ax, bx
    mov dl, al
    shr al, 4         
    and dl, 0x0F       

    call .nibble_to_char
    mov [si], al
    inc si

    mov al, dl
    call .nibble_to_char
    mov [si], al
    inc si

    mov byte [si], 0   ; null terminate

    pop dx
    pop bx
    pop ax
    ret

    .nibble_to_char:
        cmp al, 10
        jb .digit
        add al, 'A' - 10
        ret
    .digit:
        add al, '0'
        ret

; Converts a value in BX to a 2-character hex string at [SI]
byte_to_hex:
    push ax
    push bx
    push cx
    push si
    mov al, bl
    

    shr al, 4           
    call .nibble_to_char
    mov [si], al
    inc si

    mov al, bl
    and al, 0x0F       
    call .nibble_to_char
    mov [si], al
    inc si

    ; Null terminator
    mov byte [si], 0
    pop si
    pop cx
    pop bx
    pop ax
    ret

    .nibble_to_char:
        cmp al, 9
        jle .is_digit
        add al, 'A' - 10    ; For A-F
        ret
    .is_digit:
        add al, '0'         ; For 0-9
        ret

; Converts a 2-character hex string [si] to a value in bx
hex_to_byte:
    xor bx, bx
    mov al, [si]
    call .digit_hex
    mov ch, al
    mov al, [si + 1]
    call .digit_hex
    mov cl, al

    mov al, ch  ; times 16
    mov bl, 16
    mul bl
    add al, cl  
    mov bl, al
    ret


    .digit_hex:
        cmp al, '0'  ; check if its a number      
        jl .letter_hex
        cmp al, '9'        
        jg .letter_hex

        sub al, '0'        ; ascii number to decimal
        ret
        .letter_hex:
            cmp al, 'a' ; check if its a lettter
            jl error
            cmp al, 'f'
            jg error

            sub al, 'a'        ; ascii letter to decimal
            add al, 10   
            ret    

; --- FILE SYS ---

load_file_table:
    mov ah, 0x02
    mov al, 2             
    mov ch, 0
    mov cl, 11           
    mov dh, 0
    mov dl, [drive]
    mov bx, file_table_buffer
    int 0x13
    ret
write_file_table:
    push ax
    mov ah, 0x03
    mov al, 2              ; write 2 sectors
    mov ch, 0
    mov cl, 11             ; start at sector 10 (11)
    mov dh, 0
    mov dl, [drive]
    mov bx, file_table_buffer
    int 0x13
    pop ax
    ret

; txt_buffer = text and bl = sector
write_sector:
    add bx, 1
    mov ah, 0x00     ; reset disk
    mov dl, [drive]
    int 0x13

    mov ax, 0x0301       
    mov ch, 0       
    mov cl, bl             
    mov dh, 0               
    mov dl, [drive]            
    push ds
    pop es
    mov bx, txt_buffer      
    int 0x13                
    jnc .done            

    call error   
    ret
    .done:
        ret
; txt_buffer = text and bl = sector
read_sector:
    mov ax, ds           
    mov es, ax
    add bx, 1
    mov ah, 0x02
    mov al, 1
    
    call find_disk_address

    mov dl, [drive]
    mov bx, txt_buffer
    int 0x13
    jc error
    ret

; INPUT: SI = address of filename string
; OUTPUT: AX = sector number, or 0 if not found
find_file:
    mov bx, file_table_buffer
    mov dx, 64                    ; scan 64 entries
    .next_entry:
        cmp byte [bx], 0
        je .skip                      
        
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
        xor ax, ax                   
        ret
    .found:
        mov ax, [bx + FILE_ENTRY_SIZE - 3]
        ret

find_free_sector:
    mov bx, file_table_buffer
    mov cx, 64                    
    .check_entry:
        cmp byte [bx], 0               
        je .found
        add bx, FILE_ENTRY_SIZE
        loop .check_entry

        xor ax, ax                    
        ret
    .found:
        mov ax, [bx + FILE_ENTRY_SIZE - 3]   
        ret

; check if value is not too long and exists
; ax = max length
check_value:
    ; check if it exists
    cmp byte [value], 0
    je error
    cmp byte [value], 0x20 
    je error
    ; check length
    mov si, value
    xor cx, cx
    .count_loop:
        cmp byte [si], 0
        je .count_done
        cmp byte [si], 0x20
        je error
        inc cx
        inc si
        cmp cx, ax ; check length ax = max
        ja error
        jmp .count_loop
    .count_done:
    mov ax, 1
    ret

; si = file name, ax = 1 (.bin file)
check_extension:
    xor cx, cx
    push si
    .count_loop:
        cmp byte [si], 0
        je .count_done
        inc cx
        inc si
        jmp .count_loop
    .count_done:
    pop si
      
    add si, cx        
    sub si, 4         
    mov di, bin_extension    ; reference string
    mov cx, 4
    repe cmpsb
    jne .no_match          ; no match means not a bin file

    mov ax, 1
    ret
    .no_match:
        mov ax, 0
        ret

find_disk_address:
    cmp byte [drive], 0x80
    je .disk

    cmp bl, 17        
    jbe .floppy_head_0
    
    sub bl, 18          
    mov dh, 1          
    mov ch, 0           
    inc bl             
    mov cl, bl
    ret

    .floppy_head_0:
        mov ch, 0           
        mov dh, 0           
        inc bl            
        mov cl, bl
        ret

    .disk:
        mov ch, 0           
        inc bl          
        mov cl, bl                       
        mov dh, 0    
        ret


; ----- MEMORY -----
; di = destination
; si = source
mov_index_data:
    lodsb          
    stosb           
    test al, al     
    jnz mov_index_data      
    ret

; ----- TIME -----
delay:           
    push ax         
    mov cx, 1000 
    mul cx

    mov cx, dx      
    mov dx, ax      
    mov ah, 0x86
    int 0x15
    pop ax
    ret

; ----- ERROR -----
error:
    mov si, err_msg
    call new_line
    call print
    call new_line
    call clear_input
    jmp main
