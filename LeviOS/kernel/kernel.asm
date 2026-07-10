[org 0x0000]

FILE_ENTRY_SIZE equ 16

start:
    mov ax, cs
    mov ds, ax
    mov es, ax

    call clear_input        ; initialize command/value buffers and input state

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