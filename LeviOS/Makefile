# --- Configuration ---
ASM = nasm
QEMU = qemu-system-i386
BOOT = boot/boot.asm
KERNEL = kernel/kernel.asm
FILES_DIR = files
BUILD_DIR = build
DISK = $(BUILD_DIR)/disk.img

BOOT_BIN = $(BUILD_DIR)/boot.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
FILETABLE1 = $(BUILD_DIR)/filetable1.bin
FILETABLE2 = $(BUILD_DIR)/filetable2.bin

# --- Targets ---
all: $(DISK)

# Build Bootloader
$(BOOT_BIN): $(BOOT) | $(BUILD_DIR)
	$(ASM) -f bin $(BOOT) -o $(BOOT_BIN)

# Build Kernel
$(KERNEL_BIN): $(KERNEL) | $(BUILD_DIR)
	$(ASM) -f bin $(KERNEL) -i kernel/ -o $(KERNEL_BIN)

# Create directory for build artifacts
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)


$(FILETABLE1): | $(BUILD_DIR)
	@rm -f $(FILETABLE1)
	@printf "levi.txt\x00\x00\x00\x00\x00\x0C\x00\x00" >> $(FILETABLE1)
	@printf "leska.txt\x00\x00\x00\x00\x0D\x00\x00" >> $(FILETABLE1)
	@printf "test.bin\x00\x00\x00\x00\x00\x0E\x00\x00" >> $(FILETABLE1)
	@printf "fbird.bin\x00\x00\x00\x00\x0F\x00\x00" >> $(FILETABLE1)
	@printf "snake.bin\x00\x00\x00\x00\x10\x00\x00" >> $(FILETABLE1)
	@for i in $$(seq 17 43); do \
		printf '\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' >> $(FILETABLE1); \
		printf "$$(printf '\\x%02x' $$i)" >> $(FILETABLE1); \
		printf '\x00\x00' >> $(FILETABLE1); \
	done
$(FILETABLE2): | $(BUILD_DIR)
	@rm -f $(FILETABLE2)
	@printf "lexi.txt\x00\x00\x00\x00\x00\x2C\x00\x00" >> $(FILETABLE2)
	@for i in $$(seq 45 63); do \
		printf '\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' >> $(FILETABLE2); \
		printf "$$(printf '\\x%02x' $$i)" >> $(FILETABLE2); \
		printf '\x00\x00' >> $(FILETABLE2); \
	done

# Assemble Disk Image
$(DISK): $(BOOT_BIN) $(KERNEL_BIN) $(FILETABLE1) $(FILETABLE2)
	dd if=/dev/zero of=$(DISK) bs=512 count=64 2>/dev/null
	
	# 2. Write Bootloader to Sector 0
	dd if=$(BOOT_BIN) of=$(DISK) bs=512 count=1 conv=notrunc 2>/dev/null
	
	# 3. Write Kernel to Sector 1
	dd if=$(KERNEL_BIN) of=$(DISK) bs=512 seek=1 count=9 conv=notrunc 2>/dev/null
	
	# 4. Write File Table to Sector 10 and 11
	dd if=$(FILETABLE1) of=$(DISK) bs=512 seek=10 count=1 conv=notrunc 2>/dev/null
	dd if=$(FILETABLE2) of=$(DISK) bs=512 seek=11 count=1 conv=notrunc 2>/dev/null
	
	# 5. Write files
	dd if=$(FILES_DIR)/cats.txt of=$(DISK) bs=512 seek=12 count=1 conv=notrunc 2>/dev/null
	dd if=$(FILES_DIR)/cats1.txt of=$(DISK) bs=512 seek=13 count=1 conv=notrunc 2>/dev/null
	dd if=$(FILES_DIR)/test.bin of=$(DISK) bs=512 seek=14 count=1 conv=notrunc 2>/dev/null
	dd if=$(FILES_DIR)/fbird.bin of=$(DISK) bs=512 seek=15 count=1 conv=notrunc 2>/dev/null
	dd if=$(FILES_DIR)/snake.bin of=$(DISK) bs=512 seek=16 count=1 conv=notrunc 2>/dev/null
	dd if=$(FILES_DIR)/cats2.txt of=$(DISK) bs=512 seek=44 count=1 conv=notrunc 2>/dev/null

# Execution
run: $(DISK)
	$(QEMU) -drive format=raw,file=$(DISK) -display gtk

programs:
	$(ASM) -f bin files/asm_programs/test.asm -o files/test.bin
	$(ASM) -f bin files/asm_programs/fbird.asm -o files/fbird.bin
	$(ASM) -f bin files/asm_programs/snake.asm -o files/snake.bin
# yes they run 

clean:
	rm -rf $(BUILD_DIR) $(DISK)