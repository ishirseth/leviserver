# Sector layout:
# 0: bootloader (512 bytes)
# 1-9: kernel (512 bytes)
# 10: filetable (512 bytes starting 0x1400)
# intel hex: [30 bytes file name + sector (last two bytes)]
# 11...: files (512 bytes each)

