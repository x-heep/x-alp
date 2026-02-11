# Copyright X-HEEP contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# ============================================================================
# Project Configuration
# ============================================================================
XALP := x-heep:x-alp:x-alp:0.0.1
mkfile_path := $(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")

$(info Executing from: $(mkfile_path))

# ============================================================================
# Python Environment Setup
# ============================================================================
VENVDIR ?= $(WORKDIR)/.venv
REQUIREMENTS_TXT ?= util/python-requirements.txt docs/python-requirements.txt
export FILE_FOR_HELP := $(mkfile_path)/Makefile

include Makefile.venv

# Select Python tooling (conda or venv)
ifdef CONDA_DEFAULT_ENV
  $(info Using Miniconda environment: $(CONDA_DEFAULT_ENV))
  FUSESOC := $(shell which fusesoc)
  PYTHON := $(shell which python)
else
  $(info Using virtual environment)
  FUSESOC := $(PWD)/$(VENV)/fusesoc
  PYTHON := $(PWD)/$(VENV)/python
endif

# ============================================================================
# Build Configuration
# ============================================================================

# Build directories
BUILD_DIR         = build
FUSESOC_BUILD_DIR = $(shell find $(BUILD_DIR) -maxdepth 1 -type d -name 'openhwgroup.org_systems_core-v-mcu_*' 2>/dev/null | sort -V | head -n 1)
VERILATOR_DIR     = $(FUSESOC_BUILD_DIR)/sim-verilator
QUESTASIM_DIR     = $(FUSESOC_BUILD_DIR)/sim-modelsim

# FuseSoC arguments
FUSESOC_ARGS ?=

# Verilator simulation parameters
LOG_LEVEL ?= LOG_DEBUG
BINARY ?= $(mkfile_path)/sw/build/main.spm.elf
BOOTMODE ?= force
MAX_CYCLES ?= 1000000
BUILD_STAMP := build/.verilator-build-stamp

# Application build parameters
PROJECT ?= hello_world
TARGET ?= sim
LINKER ?= on_chip
LINK_FOLDER := $(mkfile_path)/sw/linker
COMPILER ?= gcc
COMPILER_PREFIX ?= riscv32-corev-
COMPILER_FLAGS ?= -mabi=lp64d
ARCH ?= rv64gc_zifencei
SOURCE ?=

# MCU-Gen template files to generate
MCU_GEN_TEMPLATES = $(shell find . \( -path './hw/vendor' -o -path './util' -o -path './test' \) -prune -o -name '*.tpl' -print)

# Mcu-gen configuration files
PADS_CFG ?= config/pad_cfg.hjson
XALP_CFG ?= config/config.py
# Cached mcu-gen xheep configuration
XALP_CONFIG_CACHE ?= $(BUILD_DIR)/xalp_config_cache.pickle

# Export variables to sub-makefiles
export

# ============================================================================
# Phony Targets
# ============================================================================
.PHONY: help conda clean clean-app clean-all \
        app app-list \
        verilator-build verilator-run verilator-waves \
        format lint \
        .check-fusesoc .check-gtkwave .check-verible .check-verilator

# ============================================================================
# Default Target
# ============================================================================
help:
	@$(mkfile_path)/util/MakefileHelp

# ============================================================================
# Environment Setup
# ============================================================================

## @section Conda
conda:
	@conda env create -f util/conda_environment.yml

# ============================================================================
# MCU Code Generation
# ============================================================================

## @section MCU Code Generation
mcu-gen:
	$(PYTHON) util/mcu_gen.py --cached_path $(XALP_CONFIG_CACHE) --config $(XALP_CFG) --pads_cfg $(PADS_CFG)
	$(PYTHON) util/mcu_gen.py --cached_path $(XALP_CONFIG_CACHE) --cached --outtpl "$(MCU_GEN_TEMPLATES)"
	@$(MAKE) reg-gen
	@$(MAKE) boot-rom
	@$(MAKE) format

## @section Register Generation
reg-gen:
	@cd hw/ip/fast_intr_ctrl && ./fast_intr_ctrl_gen.sh && cd - > /dev/null
	@cd hw/ip/soc_ctrl && ./soc_ctrl_gen.sh && cd - > /dev/null

## @section Boot ROM Build
boot-rom:
	@$(MAKE) -C hw/ip/bootrom clean all

# ============================================================================
# Application Firmware Build
# ============================================================================

## @section APP FW Build

## Generates the build folder in sw using CMake to build (compile and linking)
## @param PROJECT=<folder_name_of_the_project_to_be_built>
## @param TARGET=sim(default),systemc,pynq-z2,nexys-a7-100t,zcu104,zcu102
## @param LINKER=on_chip(default),flash_load,flash_exec
## @param COMPILER=gcc(default),clang
## @param COMPILER_PREFIX=riscv32-corev-(default),riscv32-unknown-
## @param ARCH=rv32imc(default),<any_RISC-V_ISA_string_supported_by_the_CPU>
app: clean-app
	@$(MAKE) -C sw \
		PROJECT=$(PROJECT) \
		TARGET=$(TARGET) \
		LINKER=$(LINKER) \
		LINK_FOLDER=$(LINK_FOLDER) \
		COMPILER=$(COMPILER) \
		COMPILER_PREFIX=$(COMPILER_PREFIX) \
		COMPILER_FLAGS=$(COMPILER_FLAGS) \
		ARCH=$(ARCH) \
		SOURCE=$(SOURCE) \
	|| { \
	echo "\033[0;31mHmmm... seems like the compilation failed...\033[0m"; \
	echo "\033[0;31mIf you do not understand why, it is likely that you either:\033[0m"; \
	echo "\033[0;31m  a) offended the Leprechaun of Electronics\033[0m"; \
	echo "\033[0;31m  b) forgot to run make mcu-gen\033[0m"; \
	echo "\033[0;31m  c) forgot to set the correct compiler parameters (check the docs!)\033[0m"; \
	echo "\033[0;31mI would start by checking b) or c) if I were you!\033[0m"; \
	exit 1; \
	}
	@$(PYTHON) util/mem_usage.py

## Just list the different application names available
app-list:
	@echo "Note: Applications outside the X-ALP sw/applications directory will not be listed."
	@tree sw/applications/

# ============================================================================
# Simulation
# ============================================================================

## @section Simulation

## Verilator simulation build
verilator-build:
	@$(FUSESOC) --cores-root . run --no-export --target sim --tool verilator --build $(XALP) $(FUSESOC_ARGS) 2>&1 | tee buildsim.log
	@mkdir -p $(dir $@)

## Verilator simulation run
verilator-run:
	@$(FUSESOC) run --no-export --target sim --tool verilator --run $(XALP) \
		--LOG_LEVEL=$(LOG_LEVEL) \
		--BINARY=$(BINARY) \
		--BOOTMODE=$(BOOTMODE) \
		--MAX_CYCLES=$(MAX_CYCLES) \
		--trace=true \
		$(FUSESOC_ARGS)
	@echo "Simulation finished."
	@cat ./build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/uart0.log

## Verilator wave viewer
verilator-waves: .check-gtkwave
	@gtkwave build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/waveform.fst util/wave.gtkw

# ============================================================================
# Code Quality
# ============================================================================

## @section formatting and linting

## Format
format: .check-fusesoc
	@$(FUSESOC) $(FUSESOC_FLAGS) run --no-export --target format $(XALP)
	git ls-files -z -- '*.c' '*.h' '*.cpp' '*.hpp' ':(exclude)build/**' ':(exclude)**/vendor/**' | xargs -0 clang-format -i -style=file:util/.clang-format

## Lint
lint: .check-fusesoc
	@$(FUSESOC) $(FUSESOC_FLAGS) run --no-export --target lint $(XALP)

# ============================================================================
# Cleaning
# ============================================================================

## @section Cleaning commands

## Remove the sw build folder
clean-app:
	@rm -rf sw/build

## Remove the build folders
clean: clean-app
	@rm -rf $(BUILD_DIR) $(BUILD_STAMP)

## Leave the repository in a clean state, removing all generated files
clean-all: clean

# ============================================================================
# Utilities & Checks
# ============================================================================

## @section Utilities

# Check if FuseSoC is available
.check-fusesoc:
	@command -v fusesoc >/dev/null 2>&1 || { \
		printf "\033[0;31m✗ ERROR: 'fusesoc' not found in PATH\033[0m\n" >&2; \
		printf "Is the correct conda environment active?\n" >&2; \
		exit 1; \
	}

# Generic program checker template
define CHECK_PROGRAM
.check-$(1):
	@command -v $(2) >/dev/null 2>&1 || { \
		printf "\033[0;31m✗ ERROR: '$(2)' not found in PATH\033[0m\n" >&2; \
		exit 1; \
	}
endef

# Instantiate checks for required tools
$(eval $(call CHECK_PROGRAM,gtkwave,gtkwave))
$(eval $(call CHECK_PROGRAM,verible,verible-verilog-format))
$(eval $(call CHECK_PROGRAM,verilator,verilator))