# Copyright X-HEEP contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

MAKE	= make

XALP    = x-heep:x-alp:x-alp:0.0.1

# Get the absolute path
mkfile_path := $(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")
$(info $$You are executing from: $(mkfile_path))

# Include the self-documenting tool
export FILE_FOR_HELP=$(mkfile_path)/Makefile

help:
	${mkfile_path}/util/MakefileHelp

# Setup to autogenerate python virtual environment
VENVDIR?=$(WORKDIR)/.venv
REQUIREMENTS_TXT ?= util/python-requirements.txt docs/python-requirements.txt
include Makefile.venv

# FUSESOC and Python values (default)
ifndef CONDA_DEFAULT_ENV
$(info USING VENV)
FUSESOC 	= $(PWD)/$(VENV)/fusesoc
PYTHON  	= $(PWD)/$(VENV)/python
else
$(info USING MINICONDA $(CONDA_DEFAULT_ENV))
FUSESOC 	:= $(shell which fusesoc)
PYTHON  	:= $(shell which python)
endif

# X-HEEP GEN path
XHEEP_GEN := $(mkfile_path)/hw/vendor/eslepfl_xheep

# Build directories
BUILD_DIR         = build
FUSESOC_BUILD_DIR = $(shell find $(BUILD_DIR) -maxdepth 1 -type d -name 'openhwgroup.org_systems_core-v-mcu_*' 2>/dev/null | sort -V | head -n 1)
VERILATOR_DIR     = $(FUSESOC_BUILD_DIR)/sim-verilator
QUESTASIM_DIR     = $(FUSESOC_BUILD_DIR)/sim-modelsim

# Project options are based on the app to be built (default - hello_world)
PROJECT  ?= hello_world

# Folder where the linker scripts are located
LINK_FOLDER ?= $(mkfile_path)/sw/linker
# Linker options are 'on_chip' (default),'flash_load','flash_exec','freertos'
LINKER   ?= on_chip

# Target options are 'sim' (default) and 'pynq-z2' and 'nexys-a7-100t'
TARGET   	?= sim

# Mcu-gen configuration files
PYTHON_XALP_CFG ?= util/x_alp_gen/XAlp.py
# Cached mcu-gen xalp configuration
XALP_CONFIG_CACHE ?= $(BUILD_DIR)/xalp_config_cache.pickle

MCU_GEN_TEMPLATES = \
	hw/system/core_v_mcu.sv.tpl 
# hw/system/include/core_v_mcu_pkg.sv.tpl

# Compiler prefix options are 'riscv32-corev-' (default) and 'riscv32-unknown-'
COMPILER_PREFIX ?= riscv32-corev-
# Compiler flags to be passed (for both linking and compiling)
COMPILER_FLAGS 	?=
# Arch options are any RISC-V ISA string supported by the CPU. Default 'rv32imc_zicsr'
ARCH     		?= rv32imc_zicsr

# Path relative from the location of sw/Makefile from which to fetch source files. The directory of that file is the default value.
SOURCE 	 ?= $(".")

# Simulation engines options are verilator (default) and questasim
SIMULATOR ?= verilator
# SIM_ARGS: Additional simulation arguments for run-app-verilator based on input parameters:
# - MAX_SIM_TIME: Maximum simulation time in clock cycles (unlimited if not provided)
SIM_ARGS += $(if $(MAX_SIM_TIME),+max_sim_time=$(MAX_SIM_TIME))

# Helper variables for Make string manipulation
empty :=
space := $(empty) $(empty)
comma := ,

# Testing flags
# Optional TEST_FLAGS options are '--compile-only'
TEST_FLAGS=

# Flash read address for testing, in hexadecimal format 0x0000
FLASHREAD_ADDR ?= 0x0
FLASHREAD_FILE ?= $(mkfile_path)/flashcontent.hex
FLASHREAD_BYTES ?= 256
# Binary to store in flash memory
FLASHWRITE_FILE ?= $(mkfile_path)/sw/build/main.hex
# Max address in the hex file, used to program the flash
ifeq ($(wildcard $(FLASHWRITE_FILE)),)
	MAX_HEX_ADDRESS  := 0
	MAX_HEX_ADDRESS_DEC := 0
	BYTES_AFTER_MAX_HEX_ADDRESS := 0
	FLASHWRITE_BYTES := 0
else
	MAX_HEX_ADDRESS  := $(shell cat $(FLASHWRITE_FILE) | grep "@" | tail -1 | cut -c2-)
	MAX_HEX_ADDRESS_DEC := $(shell printf "%d" 0x$(MAX_HEX_ADDRESS))
	BYTES_AFTER_MAX_HEX_ADDRESS := $(shell tac $(FLASHWRITE_FILE) | awk 'BEGIN {count=0} /@/ {print count; exit} {count++}')
	FLASHWRITE_BYTES := $(shell echo $$(( $(MAX_HEX_ADDRESS_DEC) + $(BYTES_AFTER_MAX_HEX_ADDRESS)*16 )))
endif

# Export variables to sub-makefiles
export

## @section Conda
conda:
	conda env create -f util/conda_environment.yml

## @section Installation

## Generates mcu files core-v-mcu files and build the design with fusesoc
## @param CPU=[cv32e20(default),cv32e40p,cv32e40x,cv32e40px]
## @param BUS=[onetoM(default),NtoM]
## @param MEMORY_BANKS=[2(default)to(16-MEMORY_BANKS_IL)]
## @param MEMORY_BANKS_IL=[0(default),2,4,8]
## @param XALP_CFG=[configs/general.hjson(default),<path-to-config-file>]
## @param PYTHON_XALP_CFG=[configs/general.py(default),<path-to-config-file>]
mcu-gen:
	$(PYTHON) $(XHEEP_GEN)/util/mcu_gen.py --cached_path $(XALP_CONFIG_CACHE) --python_config $(PYTHON_XALP_CFG)
	$(PYTHON) $(XHEEP_GEN)/util/mcu_gen.py --cached_path $(XALP_CONFIG_CACHE) --cached --outtpl hw/system/core_v_mcu.sv.tpl 
# "$(subst $(space),$(comma),$(MCU_GEN_TEMPLATES))"
	$(MAKE) verible

## Display mcu_gen.py help
mcu-gen-help:
	$(PYTHON) util/mcu_gen.py -h

# Format
.PHONY: format
format: .check-fusesoc
	$(FUSESOC) $(FUSESOC_FLAGS) run --no-export --target format $(XALP)

# Lint
.PHONY: lint
lint: .check-fusesoc
	$(FUSESOC) $(FUSESOC_FLAGS) run --no-export --target lint $(XALP)

## Runs black formating for python xalp generator files
format-python:
	$(PYTHON) -m black util/xalp_gen.py
	$(PYTHON) -m black util/periph_structs_gen.py
	$(PYTHON) -m black util/mcu_gen.py
	$(PYTHON) -m black util/waiver-gen.py
	$(PYTHON) -m black util/c_gen.py
	$(PYTHON) -m black test/test_xalp_gen

## @section APP FW Build

## Generates the build folder in sw using CMake to build (compile and linking)
## @param PROJECT=<folder_name_of_the_project_to_be_built>
## @param TARGET=sim(default),systemc,pynq-z2,nexys-a7-100t,zcu104,zcu102
## @param LINKER=on_chip(default),flash_load,flash_exec
## @param COMPILER=gcc(default),clang
## @param COMPILER_PREFIX=riscv32-corev-(default),riscv32-unknown-
## @param ARCH=rv32imc(default),<any_RISC-V_ISA_string_supported_by_the_CPU>
app: clean-app
	@$(MAKE) -C sw PROJECT=$(PROJECT) TARGET=$(TARGET) LINKER=$(LINKER) LINK_FOLDER=$(LINK_FOLDER) COMPILER=$(COMPILER) COMPILER_PREFIX=$(COMPILER_PREFIX) COMPILER_FLAGS=$(COMPILER_FLAGS) ARCH=$(ARCH) SOURCE=$(SOURCE) \
	|| { \
	echo "\033[0;31mHmmm... seems like the compilation failed...\033[0m"; \
	echo "\033[0;31mIf you do not understand why, it is likely that you either:\033[0m"; \
	echo "\033[0;31m  a) offended the Leprechaun of Electronics\033[0m"; \
	echo "\033[0;31m  b) forgot to run make mcu-gen\033[0m"; \
	echo "\033[0;31m  c) forgot to set the correct compiler parameters (check the docs!)\033[0m"; \
	echo "\033[0;31mI would start by checking b) or c) if I were you!\033[0m"; \
	exit 1; \
	}
	@python scripts/building/mem_usage.py

## Just list the different application names available
app-list:
	@echo "Note: Applications outside the X-HEEP sw/applications directory will not be listed."
	tree sw/applications/

## @section Simulation

## Verilator simulation with C++
verilator-build: | .check-verilator
	$(FUSESOC) --cores-root . run --no-export --target=simulate --tool=verilator $(FUSESOC_FLAGS) --build x-heep:x-alp:x-alp:0.0.1 $(FUSESOC_PARAM) 2>&1 | tee buildsim.log

## @section Cleaning commands

## Remove the sw build folder
.PHONY: clean-app
clean-app:
	@rm -rf sw/build

## Remove the build folders
.PHONY: clean
clean: clean-app
	@rm -rf $(BUILD_DIR)

## Leave the repository in a clean state, removing all generated files. For now, it just calls clean.
.PHONY: clean-all
clean-all: clean

## @section Utilities

# Check FuseSoC
.PHONY: .check-fusesoc
.check-fusesoc:
	@if [ ! `which fusesoc` ]; then \
	printf -- "### ERROR: 'fusesoc' is not in PATH. Is the correct conda environment active?\n" >&2; \
	exit 1; fi

# Check if a program is available in PATH
define CHECK_PROGRAM
.PHONY: .check-$(1)
.check-$(1):
	@command -v $(2) >/dev/null 2>&1 || { \
		printf "### ERROR: '%s' is not in PATH.\\n" "$(2)" >&2; \
		exit 1; \
	}
endef
$(eval $(call CHECK_PROGRAM,gtkwave,gtkwave))
$(eval $(call CHECK_PROGRAM,verible,verible-verilog-format))
$(eval $(call CHECK_PROGRAM,verilator,verilator))