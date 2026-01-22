# See LICENSE.SiFive for license details

boot_rom = boot_rom.sv

GCC?=$(RISCV_XALP)/bin/$(COMPILER_PREFIX)elf-gcc
OBJCOPY?=$(RISCV_XALP)/bin/$(COMPILER_PREFIX)elf-objcopy
OBJDUMP?=$(RISCV_XALP)/bin/$(COMPILER_PREFIX)elf-objdump
PYTHON?=python

INC_FOLDERS                 = $(sort $(dir $(wildcard ../../../sw/device/lib/drivers/*/)))
INC_FOLDERS                += $(sort $(dir $(wildcard ../../../sw/device/lib/base/*/)))
INC_FOLDERS                += $(sort $(dir $(wildcard ../../../sw/device/lib/runtime/)))
INC_FOLDERS_GCC             = $(addprefix -I ,$(INC_FOLDERS))

# Boot ROM (needs SW stack)
BOOTROM_DIR = $(mkfile_path)/hw/ip/bootrom

SW_FLAGS   ?= -DOT_PLATFORM_RV32 -march=rv64gc_zifencei -mabi=lp64d -mstrict-align -O2 -Wall -Wextra -static -ffunction-sections -fdata-sections -fuse-linker-plugin -flto -Wl,-flto
SW_LDFLAGS ?= $(SW_FLAGS) -nostartfiles -Wl,--gc-sections -Wl,-L$(LINK_FOLDER) -Wl,--no-relax

BROM_SRCS = $(wildcard $(BOOTROM_DIR)/*.S $(BOOTROM_DIR)/*.c)
BROM_FLAGS = $(SW_LDFLAGS) -Os -fno-zero-initialized-in-bss -flto -fwhole-program

$(BOOTROM_DIR)/bootrom.elf: $(BOOTROM_DIR)/bootrom.ld $(BROM_SRCS)
	$(GCC) -T$< $(BROM_FLAGS) -o $@ $(BROM_SRCS) $(INC_FOLDERS_GCC)

$(BOOTROM_DIR)/bootrom.bin: $(BOOTROM_DIR)/bootrom.elf
	$(OBJCOPY) -O binary $< $@
	$(OBJDUMP) -D $< > $(BOOTROM_DIR)/bootrom.dump

$(BOOTROM_DIR)/bootrom.sv: $(BOOTROM_DIR)/bootrom.bin $(BOOTROM_DIR)/gen_bootrom.py
	$(PYTHON) $(BOOTROM_DIR)/gen_bootrom.py --sv-module bootrom $< > $@

BOOTROM_ALL += $(BOOTROM_DIR)/bootrom.sv $(BOOTROM_DIR)/bootrom.dump

all: $(BOOTROM_ALL)

clean:
	rm -f *.img *.bin *.sv .*dump

