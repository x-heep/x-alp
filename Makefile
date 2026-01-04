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

# FuseSoC args
FUSESOC_ARGS    ?= 

# Verilator simulation parameters
LOG_LEVEL	?= LOG_DEBUG
BINARY      ?= ""
BOOTMODE    ?= force
MAX_CYCLES  ?= 1000000

# Export variables to sub-makefiles
export

## @section Conda
conda:
	conda env create -f util/conda_environment.yml

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

## Verilator simulation
verilator-build: | .check-verilator
	$(FUSESOC) --cores-root . run --no-export --target sim --tool verilator --build x-heep:x-alp:x-alp:0.0.1 $(FUSESOC_ARGS) 2>&1 | tee buildsim.log

verilator-run: | verilator-build
	$(FUSESOC) run --no-export --target sim --tool verilator --run x-heep:x-alp:x-alp:0.0.1 \
		--LOG_LEVEL=$(LOG_LEVEL) \
		--BINARY=$(BINARY) \
		--BOOTMODE=$(BOOTMODE) \
		--MAX_CYCLES=$(MAX_CYCLES) \
		--trace=true \
		$(FUSESOC_ARGS)

## @section formatting and linting

## Format
.PHONY: format
format: .check-fusesoc
	$(FUSESOC) $(FUSESOC_FLAGS) run --no-export --target format $(XALP)

## Lint
.PHONY: lint
lint: .check-fusesoc
	$(FUSESOC) $(FUSESOC_FLAGS) run --no-export --target lint $(XALP)


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