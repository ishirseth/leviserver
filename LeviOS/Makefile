# LeviOS Makefile
# qemu-system-i386 -drive format=raw,file=disk.img -display gtk
ASM = nasm
QEMU = qemu-system-i386

BOOT = boot/boot.asm
KERNEL = kernel/kernel.asm

BOOT_BIN = boot/boot.bin
KERNEL_BIN = kernel/kernel.bin
DISK = disk.img

all: $(DISK)

# --- build bootloader ---
$(BOOT_BIN): $(BOOT)
	$(ASM) -f bin $(BOOT) -o $(BOOT_BIN)

# --- build kernel ---
$(KERNEL_BIN): $(KERNEL)
	$(ASM) -f bin $(KERNEL) -o $(KERNEL_BIN)

# --- create disk image ---
$(DISK): $(BOOT_BIN) $(KERNEL_BIN)
	dd if=/dev/zero of=$(DISK) bs=512 count=100 2>/dev/null
	dd if=$(BOOT_BIN) of=$(DISK) bs=512 count=1 conv=notrunc 2>/dev/null
	dd if=$(KERNEL_BIN) of=$(DISK) bs=512 seek=1 count=1 conv=notrunc 2>/dev/null
# --- Loop through files in the 'files/' folder ---
	@count=11; \
	for file in files/*.txt; do \
		echo "Writing $$file to sector $$count"; \
		dd if=$$file of=$(DISK) bs=512 seek=$$count conv=notrunc 2>/dev/null; \
		count=$$((count + 1)); \
	done

run: $(DISK)
	$(QEMU) -drive format=raw,file=$(DISK) -display gtk

clean:
	rm -f $(BOOT_BIN) $(KERNEL_BIN) $(DISK)