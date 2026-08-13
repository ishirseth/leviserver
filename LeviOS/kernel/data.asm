; --- Commands ---

levi_command: db "levi", 0
echo_command: db "echo", 0
read_command: db "read", 0
write_command: db "write", 0
write_data_command: db "writedata", 0
delete_command: db "delete", 0
ls_command: db "ls", 0
sl_command: db "sl", 0
clear_command: db "clear", 0
run_command: db "run", 0
help_command: db "help", 0

; --- Command Messages ---

levi_str: db "-Levi says hi!", 0
read_str1: db "-Reading ", 0
read_str2: db " at sector ", 0
write_str: db "-Selected ", 0
write_data_str: db "-Writing to ", 0
delete_str: db "-Deleting ", 0

; --- Other ---
drive: db 0x80
bin_extension: db ".bin", 0

; --- Messages ---
msg: db "LeviOS"
    db " ", 0x0D,0x0A, 0
err_msg:     db "Error!", 0
done_msg: db "Done.", 0
help_msg:
    db "levi - prints the levi message", 0x0D,0x0A
    db "echo <msg> - echoes back what you wrote", 0x0D,0x0A
    db "ls - lists all files and programs", 0x0D,0x0A
    db "read <filename> - reads a file", 0x0D,0x0A
    db "run <filename> - runs .bin programs", 0x0D,0x0A
    db "write <filename> - creates/selects a file to then write data to", 0x0D,0x0A
    db "writedata <file contents> - writes to the file selected with write, for .bin files use lowercase hex with spaces between", 0x0D,0x0A
    db "delete <filename> - deletes a file", 0x0D,0x0A
    db "clear - clears the screen", 0x0D,0x0A
    db "sl - steam locomotive", 0x0D,0x0A
    db 0
    
init_file_name: db "levi.txt", 0
    sl_line1: db "     ooOOOO", 0
    sl_line2: db "    oo     _____", 0
    sl_line3: db "   _I__n_n__||_|| ________", 0
    sl_line4: db " >(_________|_7_|-|______|", 0
    sl_line5: db "      ()() ()() o    oo  oo", 0


section .bss
; --- State Variables ---
active_ptr:         resw 1
current_offset:     resw 2  ; (or resw 1, since a word is 2 bytes)
command_offset:     resw 1
space_pressed_flag: resb 1
ignore_space_flag:  resb 1

; --- Buffers (0 bytes in your .img file!) ---
num_buffer:         resb 8
write_sector_buffer: resb 16 
write_file_buffer:  resb FILE_ENTRY_SIZE
command:            resb 32
value:              resb 1600
file_table_buffer:  resb 1024

txt_buffer:         resb 512    ; keep last