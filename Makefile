IMAGE := build/securityos.img
STAGE1 := build/stage1.bin
STAGE2 := build/stage2.bin
KERNEL := build/kernel.bin

all: $(IMAGE)

$(STAGE1): bootloader/stage1.asm
	nasm -f bin bootloader/stage1.asm -o $(STAGE1)

$(STAGE2): bootloader/stage2.asm
	nasm -f bin bootloader/stage2.asm -o $(STAGE2)

$(KERNEL): kernel/kernel.asm \
 kernel/lib.asm \
 drivers/serial.asm \
 drivers/ports.asm \
 drivers/console.asm \
 drivers/pic.asm \
 drivers/pit.asm \
 drivers/keyboard.asm \
 kernel/interrupts.asm \
 memory/paging.asm \
 security/logger.asm \
 security/engine.asm \
 sandbox/vuln_demo.asm \
 shell/shell.asm
	nasm -f bin kernel/kernel.asm -o $(KERNEL)

check-sizes: $(STAGE1) $(STAGE2) $(KERNEL)
	test $$(wc -c < $(STAGE1)) -eq 512
	test $$(wc -c < $(STAGE2)) -le $$((32 * 512))
	test $$(wc -c < $(KERNEL)) -le $$((64 * 512))

$(IMAGE): $(STAGE1) $(STAGE2) $(KERNEL) check-sizes
	dd if=/dev/zero of=$(IMAGE) bs=512 count=2880
	dd if=$(STAGE1) of=$(IMAGE) conv=notrunc
	dd if=$(STAGE2) of=$(IMAGE) bs=512 seek=1 conv=notrunc
	dd if=$(KERNEL) of=$(IMAGE) bs=512 seek=33 conv=notrunc

run: $(IMAGE)
	qemu-system-x86_64 -drive format=raw,file=$(IMAGE) -monitor stdio

run-serial: $(IMAGE)
	qemu-system-x86_64 -drive format=raw,file=$(IMAGE) -serial stdio -display none

clean:
	rm -f build/*.bin build/*.img

.PHONY: all clean run run-serial check-sizes
