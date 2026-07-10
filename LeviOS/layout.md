# Sector layout:
# 0: bootloader (512 bytes)
# 1-9: kernel (512 bytes)
# 10: filetable (512 bytes starting 0x1400)
# intel hex: []
# 11...: files (MAX 512 bytes each)

files:
-max 89 (256)
-max 512 char long (1 sector)
-max 13 char long file name (with .txt)

