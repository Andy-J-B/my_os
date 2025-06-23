ASM=nasm

SRC_DIR=src
BUILD_DIR=build

# Make it so we can refer to files easier
.PHONY: all floppy_image kernel bootloader clean always

#
### floppy image
#
floppy_image: $(BUILD_DIR)/main_floppy.img

#
### Floppy disk
#

$(BUILD_DIR)/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880 # create empty 1.44MB image
	mformat -i $(BUILD_DIR)/main_floppy.img -f 1440 -v NBOS :: # format FAT12 with volume label "NBOS"
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc # write bootloader
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin ::kernel.bin # copy kernel into image


#
### Bootloader
# rule for loading the bootloader
bootloader: $(BUILD_DIR)/bootloader.bin
$(BUILD_DIR)/bootloader.bin: always # always target for building the build directory if it doesn't exist
# so we don't get compilation errors if directory doesn't exist
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin


#
### Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always # always target for building the build directory if it doesn't exist
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

#
### Always
#
always:
	mkdir -p $(BUILD_DIR)

#
### Clean : deleted everything is build folder
#
clean:
	rm -rf $(BUILD_DIR)/*
