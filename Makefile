ASM      := nasm
CC       := gcc
LD       := ld
MKFS     := mkfs.fat
MCOPY    := mcopy
QEMU     := qemu-system-x86_64
DD       := dd

SRC      := boot
FS       := FLOPPY_FILESYSTEM
BUILD    := build
KERNEL   := kernel
OSINIT   := $(FS)/OSINIT

STAGE0   := $(BUILD)/stage0.bin
STAGE1   := $(BUILD)/stage1.bin
IMAGE    := $(BUILD)/floppy.img

SECTOR   := 512
TOTAL    := 2880
RESERVED := 4
S1SECT   := $(shell echo $$(($(RESERVED)-1)))

# Kernel sources
KERNEL_SRC := $(KERNEL)/main.c
KERNEL_LD  := $(KERNEL)/kernel.ld
KERNEL_OBJ := $(BUILD)/osinit.o

all: $(IMAGE)

# Build directories
$(BUILD):
	mkdir -p $@

# -------------------------
# Stage0
# -------------------------
$(STAGE0): $(SRC)/stage0.asm | $(BUILD)
	$(ASM) -f bin $< -o $@
	@size=$$(stat -c%s $@); [ $$size -eq $(SECTOR) ] || (echo "stage0 must be $(SECTOR) bytes"; exit 1)

# -------------------------
# Stage1
# -------------------------
$(STAGE1): $(SRC)/stage1.asm | $(BUILD)
	$(ASM) -f bin $< -o $(BUILD)/stage1_tmp.bin
	@size=$$(stat -c%s $(BUILD)/stage1_tmp.bin); \
	[ $$size -le $$(($(S1SECT)*$(SECTOR))) ] || (echo "stage1 too big"; exit 1)
	dd if=/dev/zero of=$@ bs=$(SECTOR) count=$(S1SECT) status=none
	dd if=$(BUILD)/stage1_tmp.bin of=$@ conv=notrunc status=none
	rm -f $(BUILD)/stage1_tmp.bin

# -------------------------
# Kernel / OSINIT
# -------------------------
$(OSINIT): $(KERNEL_SRC) $(KERNEL_LD) | $(BUILD)
	@echo "Compiling freestanding kernel..."
	$(CC) -m32 -ffreestanding -O0 -c $(KERNEL_SRC) -Wall -Wextra -nostdlib -fno-builtin -fno-stack-protector -funsigned-char -o $(KERNEL_OBJ)
	$(LD) -m elf_i386 -T $(KERNEL_LD) -o $(BUILD)/osinit.elf $(KERNEL_OBJ)
	objcopy -O binary $(BUILD)/osinit.elf $@
	@echo "Kernel built at $(OSINIT)"

# -------------------------
# Floppy image
# -------------------------
$(IMAGE): $(STAGE0) $(STAGE1) $(OSINIT) | $(BUILD)
	$(DD) if=/dev/zero of=$@ bs=$(SECTOR) count=$(TOTAL) status=none
	$(MKFS) -F 12 -R $(RESERVED) $@
	$(DD) if=$(STAGE0) of=$@ bs=$(SECTOR) count=1 conv=notrunc status=none
	$(DD) if=$(STAGE1) of=$@ bs=$(SECTOR) seek=1 conv=notrunc status=none
	@$(MCOPY) -i $@ -s $(FS)/* :: >/dev/null 2>&1

# -------------------------
# Run in QEMU
# -------------------------
.PHONY: run
run: $(IMAGE)
	$(QEMU) -fda $(IMAGE)

# -------------------------
# Clean
# -------------------------
.PHONY: clean
clean:
	rm -rf $(BUILD)
