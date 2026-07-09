# --- Configuration ---
ASM = nasm
QEMU = qemu-system-i386
BOOT = boot/boot.asm
KERNEL = kernel/kernel.asm
FILES_DIR = files
BUILD_DIR = build
DISK = disk.img

BOOT_BIN = $(BUILD_DIR)/boot.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
FILETABLE = $(BUILD_DIR)/filetable.bin

# --- Targets ---
all: $(DISK)

# Build Bootloader
$(BOOT_BIN): $(BOOT) | $(BUILD_DIR)
	$(ASM) -f bin $(BOOT) -o $(BOOT_BIN)

# Build Kernel
$(KERNEL_BIN): $(KERNEL) | $(BUILD_DIR)
	$(ASM) -f bin $(KERNEL) -o $(KERNEL_BIN)

# Create directory for build artifacts
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Generate File Table (10 bytes per entry)
# Entry: "levi.txt" (8 chars) + Sector (1 byte) + Reserved (1 byte)
# Total size: 512 bytes (padded with 0s)
$(FILETABLE): | $(BUILD_DIR)
	printf "levi.txt\x0B\x00" > $(FILETABLE)
	dd if=/dev/zero bs=1 count=502 >> $(FILETABLE)

# Assemble Disk Image
$(DISK): $(BOOT_BIN) $(KERNEL_BIN) $(FILETABLE)
	# 1. Create empty 51200 byte disk (100 sectors)
	dd if=/dev/zero of=$(DISK) bs=512 count=100 2>/dev/null
	
	# 2. Write Bootloader to Sector 0
	dd if=$(BOOT_BIN) of=$(DISK) bs=512 count=1 conv=notrunc 2>/dev/null
	
	# 3. Write Kernel to Sector 1
	dd if=$(KERNEL_BIN) of=$(DISK) bs=512 seek=1 count=1 conv=notrunc 2>/dev/null
	
	# 4. Write File Table to Sector 10
	dd if=$(FILETABLE) of=$(DISK) bs=512 seek=10 count=1 conv=notrunc 2>/dev/null
	
	# 5. Write levi.txt to Sector 11
	dd if=$(FILES_DIR)/levi.txt of=$(DISK) bs=512 seek=11 count=1 conv=notrunc 2>/dev/null

# Execution
run: $(DISK)
	$(QEMU) -drive format=raw,file=$(DISK) -display gtk

clean:
	rm -rf $(BUILD_DIR) $(DISK)