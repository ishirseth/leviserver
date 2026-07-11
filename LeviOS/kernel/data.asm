
levi_command: db "levi", 0
echo_command: db "echo", 0
readtxt_command: db "read", 0
writetxt_command: db "write", 0
ls_command: db "ls", 0

levi_str: db "-Levi says hi!", 0
read_txt_str1: db "-Reading ", 0
read_txt_str2: db " at sector ", 0
write_txt_str: db "-Writing ", 0

; --- State Variables ---
active_ptr:     dw command
current_offset: dw 0
space_pressed_flag: db 0
ignore_space_flag: db 1

; --- Buffers ---
command:        times 32 db 0
value:          times 128 db 0
txt_buffer: times 512 db 0
file_table_buffer_s1: times 512 db 0

; --- Messages (moved after buffers to avoid being overwritten) ---
msg: db "LeviOS is running"
    db " ", 0x0D,0x0A, 0
err_msg:     db "Error!", 0