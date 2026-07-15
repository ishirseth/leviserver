# Sector layout (max 63 with CHS):
# 0: bootloader (512 bytes)
# 1-9: kernel (512 bytes)
# 10: filetable1 (512 bytes starting 0x1400)
# 11 - 63: files (MAX 512 bytes each)

files:
-max 32 (because file table)
-max 512 char long (1 sc)
-max 13 char long file name (with .txt)
-little endian

16 byte entries

        e l  i v  t .  t x            11  
0000000 656c 6976 742e 7478 0000 0000 0b00 0000
        ----------file name---------- scsc uuuu

# sc = sector
# fl = flag
# uu = unused
# ✔ = done

Filesys tasks:
-check that filename dosent exist on write ✔
-add ls ✔
-finish writetxt to also write content ✔
-add second filetable sc to have max 63 entries for sc (limit: 64 - 11 = 52 file sc) ✔
-add multi sc files to increase max file size X
-add file deletion ✔
-fix first char missing ✔
-add sl ✔
-add clear ✔
-add backspace
-add exectuable programs which can be ran
-add some programs and games
-make a text and program editor instead of rewriting the entire file
-add serial communication

Sector task:
-switch from CHS to LBA to increase max sectors from 63 to 2^64
 ⤷ add more filetables
 ⤷ chage write and read to use cx 
 ⤷ yeah i dont wanna do this task

Commands:
levi (levi)
echo (repeat what is written for value)
read (to read data from a file)
write (to create and select a file)
writedata (to write data to the selected file)
ls (list all files with sectors)

