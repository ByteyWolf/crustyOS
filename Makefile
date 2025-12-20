ASM      := nasm
MKFS     := mkfs.fat
MCOPY    := mcopy
QEMU     := qemu-system-x86_64
DD       := dd

SRC      := boot
FS       := FLOPPY_FILESYSTEM
BUILD    := build

STAGE0   := $(BUILD)/stage0.bin
STAGE1   := $(BUILD)/stage1.bin
IMAGE    := $(BUILD)/floppy.img

SECTOR   := 512
TOTAL    := 2880
RESERVED := 4
S1SECT   := $(shell echo $$(($(RESERVED)-1)))

all: $(IMAGE)

$(BUILD):
	mkdir -p $@

$(STAGE0): $(SRC)/stage0.asm | $(BUILD)
	$(ASM) -f bin $< -o $@
	@size=$$(stat -c%s $@); [ $$size -eq $(SECTOR) ] || (echo "stage0 must be $(SECTOR) bytes"; exit 1)

$(STAGE1): $(SRC)/stage1.asm | $(BUILD)
	$(ASM) -f bin $< -o $(BUILD)/stage1_tmp.bin
	@size=$$(stat -c%s $(BUILD)/stage1_tmp.bin); \
	[ $$size -le $$(($(S1SECT)*$(SECTOR))) ] || (echo "stage1 too big"; exit 1)
	dd if=/dev/zero of=$@ bs=$(SECTOR) count=$(S1SECT) status=none
	dd if=$(BUILD)/stage1_tmp.bin of=$@ conv=notrunc status=none
	rm -f $(BUILD)/stage1_tmp.bin

$(IMAGE): $(STAGE0) $(STAGE1) | $(BUILD)
	$(DD) if=/dev/zero of=$@ bs=$(SECTOR) count=$(TOTAL) status=none
	$(MKFS) -F 12 -R $(RESERVED) $@
	$(DD) if=$(STAGE0) of=$@ bs=$(SECTOR) count=1 conv=notrunc status=none
	$(DD) if=$(STAGE1) of=$@ bs=$(SECTOR) seek=1 conv=notrunc status=none
	@$(MCOPY) -i $@ -s $(FS)/* :: >/dev/null 2>&1


.PHONY: run
run: $(IMAGE)
	$(QEMU) -fda $(IMAGE)

.PHONY: clean
clean:
	rm -rf $(BUILD)
