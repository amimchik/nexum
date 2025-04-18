# Source directories
SRC_DIR        := src
BOOT_DIR       := $(SRC_DIR)/bootloader
KERNEL_DIR     := $(SRC_DIR)/kernel
INC_DIR        := $(SRC_DIR)/include

# Build output directories
BUILD_DIR      := build
OBJ_DIR        := $(BUILD_DIR)/obj
BIN_DIR        := $(BUILD_DIR)/bin
IMG_DIR        := $(BUILD_DIR)/img

# Bootloader and kernel binaries
BOOT_SRC       := $(BOOT_DIR)/boot.asm
BOOT_BIN       := $(BIN_DIR)/boot.bin
KERNEL_ELF     := $(BIN_DIR)/kernel.elf
TARGET         := $(IMG_DIR)/nexum.img

# Compiler and flags
CC             := i686-elf-gcc
LD             := i686-elf-ld
NASM           := nasm
CFLAGS         := -m32 -ffreestanding -nostdlib -nostartfiles -fno-builtin -fno-stack-protector -Wall -Wextra -I$(INC_DIR)
LDFLAGS        := -T linker.ld -nostdlib -m32

# Find all C source files in kernel/
KERNEL_C_FILES := $(shell find $(KERNEL_DIR) -name "*.c")

# Convert .c source paths into .o object paths in the obj/ tree
KERNEL_OBJ_DIR    := $(OBJ_DIR)/kernel
KERNEL_OBJ_FILES  := $(patsubst $(KERNEL_DIR)/%, $(KERNEL_OBJ_DIR)/%, $(KERNEL_C_FILES:.c=.o))

# Default target
all: dirs $(TARGET)

# --- Link boot.bin + kernel.elf into bootable image ---
$(TARGET): $(BOOT_BIN) $(KERNEL_ELF)
	cp $(BOOT_BIN) $@
	dd if=$(KERNEL_ELF) of=$@ bs=512 seek=1 conv=notrunc

# --- Compile bootloader to flat binary using NASM ---
$(BOOT_BIN): $(BOOT_SRC)
	$(NASM) -f bin $< -o $@

# --- Link kernel object files into ELF kernel binary ---
$(KERNEL_ELF): $(KERNEL_OBJ_FILES)
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_OBJ_FILES)

# --- Dynamically generate compilation rules for each C file ---
define COMPILE_TEMPLATE
$(1): $(2)
	@mkdir -p $(dir $(1))
	$(CC) $(CFLAGS) -c $(2) -o $(1)
endef

$(foreach cfile,$(KERNEL_C_FILES), \
  $(eval obj=$(patsubst $(KERNEL_DIR)/%, $(KERNEL_OBJ_DIR)/%, $(cfile:.c=.o))) \
  $(eval $(call COMPILE_TEMPLATE,$(obj),$(cfile))) \
)

# --- Create necessary directories ---
dirs:
	@mkdir -p $(OBJ_DIR) $(BIN_DIR) $(IMG_DIR)

# --- Clean build ---
clean:
	rm -rf $(BUILD_DIR)
	$(MAKE) dirs

