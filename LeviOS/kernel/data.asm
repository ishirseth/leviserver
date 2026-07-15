
levi_command: db "levi", 0
echo_command: db "echo", 0
readtxt_command: db "read", 0
write_command: db "write", 0
write_data_command: db "writedata", 0
delete_command: db "delete", 0
ls_command: db "ls", 0
sl_command: db "sl", 0
clear_command: db "clear", 0

levi_str: db "-Levi says hi!", 0
read_str1: db "-Reading ", 0
read_str2: db " at sector ", 0
write_str: db "-Selected ", 0
write_data_str: db "-Writing to ", 0
delete_str: db "-Deleting ", 0

; --- State Variables ---
active_ptr:     dw command
current_offset: dw 0
command_offset: dw 0
space_pressed_flag: db 0
ignore_space_flag: db 1

; --- Buffers ---
num_buffer: times 8 db 0
write_sector_buffer: times 16 db 0 ; only for write instructions DO NOT TOUCH 
write_file_buffer: times FILE_ENTRY_SIZE db 0
command:        times 32 db 0
value:          times 512 db 0
txt_buffer: times 512 db 0
file_table_buffer: times 1024 db 0

; --- Messages (moved after buffers to avoid being overwritten) ---
msg: db "LeviOS is running"
    db " ", 0x0D,0x0A, 0
err_msg:     db "Error!", 0
init_file_name: db "levi.txt", 0
    sl_line1: db "     ooOOOO", 0
    sl_line2: db "    oo      _____", 0
    sl_line3: db "   _I__n_n__||_|| ________", 0
    sl_line4: db " >(_________|_7_|-|______|", 0
    sl_line5: db "     ()() ()() o   oo  oo", 0