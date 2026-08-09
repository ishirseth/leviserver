[org 0x0000]

FILE_ENTRY_SIZE equ 16

start:
    mov ax, cs
    mov ds, ax
    mov es, ax

    mov ah, 0x01
    mov ch, 0x06     
    mov cl, 0x07  
    int 0x10

    mov [drive], 0x80   ; select drive

    mov word [write_sector_buffer], 12
    mov di, write_file_buffer
    mov si, init_file_name
    call mov_index_data

    call clear_input        

    call clear_screen
    mov si, msg
    call print
    jmp main

main:
    call read_key    
    call print_char
    jmp main

%include "lib.asm"      
%include "input.asm"    
%include "commands.asm" 
%include "data.asm"   