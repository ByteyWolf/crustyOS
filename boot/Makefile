ASM = nasm
QEMU = qemu-system-x86_64

STAGE0 = stage0.bin
STAGE1 = stage1.bin
IMAGE  = floppy.img

all: $(IMAGE)

# Assemble stage 0 (boot sector)
$(STAGE0): stage0.asm
	$(ASM) -f bin $< -o $@

# Assemble stage 1
$(STAGE1): stage1.asm
	$(ASM) -f bin $< -o $@

# Create floppy image and place stages
$(IMAGE): $(STAGE0) $(STAGE1)
	# Create empty 1.44MB floppy
	dd if=/dev/zero of=$(IMAGE) bs=512 count=2880

	# Write stage 0 to sector 0
	dd if=$(STAGE0) of=$(IMAGE) bs=512 count=1 conv=notrunc

	# Write stage 1 to sectors 1–3
	dd if=$(STAGE1) of=$(IMAGE) bs=512 seek=1 conv=notrunc

run: $(IMAGE)
	$(QEMU) -fda $(IMAGE)

clean:
	rm -f *.bin *.img
