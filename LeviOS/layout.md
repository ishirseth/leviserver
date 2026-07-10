# Sector layout (max 63 with CHS):
# 0: bootloader (512 bytes)
# 1-9: kernel (512 bytes)
# 10: filetable1 (512 bytes starting 0x1400)
# 11...: files (MAX 512 bytes each)

files:
-max 32 (because file table)
-max 512 char long (1 sc)
-max 13 char long file name (with .txt)
-little endian

        e l  i v  t .  t x            11  
0000000 656c 6976 742e 7478 0000 0000 0b00 0000
        ----------file name---------- scuu uuuu

# sc = sector
# fl = flag
# uu = unused

Filesys tasks (for when i want to have a bad day):
-check that filename dosent exist on write
-finish writetxt to also write content
-add file deletion
-add ls
-add second filetable sc to have max 63 entries for sc (limit: 64 - 11 = 52 file sc)
-add exectuable programs which can be ran
-add multi sc files to increase max file size
-make a text and program editor instead of rewriting the entire file

Sector task (for when i want to have a really really bad day):
-switch from CHS to LBA to increase max sectors from 63 to 2^64 (a whole lot of sectors)
 ⤷ add more filetables

