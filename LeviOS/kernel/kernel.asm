[org 0x0000]

FILE_ENTRY_SIZE equ 16

start:
    mov ax, cs
    mov ds, ax
    mov es, ax

    mov ah, 0x01
    mov ch, 0x06     ; bit 5 is 0 (visible), start scan line 6
    mov cl, 0x07     ; end scan line 7
    int 0x10

    mov word [write_sector_buffer], 12
    mov di, write_file_buffer
    mov si, init_file_name
    call mov_index_data

    call clear_input        ; initialize command/value buffers and input state

    call clear_screen
    mov si, msg
    call print
    jmp main

main:
    call read_key       ; AL now holds the typed character
    call print_char
    jmp main

%include "lib.asm"       ; Utility functions
%include "input.asm"     ; Logic that handles buffers and user keys
%include "commands.asm"  ; The specific command implementations
%include "data.asm"      ; Data must be first so everything else can see the buffers