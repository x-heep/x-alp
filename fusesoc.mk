# ------------
# Hardware RTL
# ------------
CHS_BUILD_DIR		?= $(CHS_ROOT)/build
CHS_SW_DIR		  ?= $(CHS_ROOT)/sw
CHS_TESTS_DIR		?= $(CHS_SW_DIR)/tests
# FuseSoc 
FUSESOC := $(shell which fusesoc)

# Simulation configuration
LOG_LEVEL			?= LOG_NORMAL
CHS_BOOT_MODE			?= force # jtag: wait for JTAG (DPI module), force: load firmware into SRAM
CHS_VCD_MODE				 ?= 1      # VCD dump mode: 0 (no dump) | 1 (active when system ready) | 2 (when system has loaded fw)
ifeq ($(CHS_BOOT_MODE), jtag)
	CHS_FIRMWARE		?= $(ROOT_DIR)/build/sw/app/main.hex.srec
else
	CHS_FIRMWARE		?= helloworld.dram.elf
endif
CHS_MAX_CYCLES			?= 3200000

CHS_FUSESOC_FLAGS	  ?= cv64a6_imafdcx_sv39
CHS_FUSESOC_ARGS		?=
CHS_SIM_TARGET 			?= sim
LLC_SET_ASSOC       ?= 8

# Check FuseSoC
.PHONY: .check-fusesoc
.check-fusesoc:
	@if [ ! `which fusesoc` ]; then \
	printf -- "### ERROR: 'fusesoc' is not in PATH. Is the correct conda environment active?\n" >&2; \
	exit 1; fi

# Format
.PHONY: chs-format
chs-format: .check-fusesoc
	$(FUSESOC) run --no-export --target format epfl:cheshire:cheshire

# Lint
.PHONY: chs-lint
chs-lint: .check-fusesoc
	$(FUSESOC) run --no-export --target lint epfl:cheshire:cheshire

# -------------------
# Verilator - FuseSoC
# -------------------
$(CHS_ROOT)/tb/src/verilator/tb_cheshire_util.svh:
	python3 $(CHS_ROOT)/tb/scripts/gen_tb_utils.py --sets-assoc $(LLC_SET_ASSOC) \
					--tpl-sv $(CHS_ROOT)/tb/src/verilator/tb_cheshire_util.svh.tpl \
					--outdir $(CHS_ROOT)/tb/src/verilator


# Build simulation model with Verilator
.PHONY: chs-verilator-build
chs-verilator-build: .check-fusesoc $(CHS_ROOT)/tb/src/verilator/tb_cheshire_util.svh chs-hw-all
	$(FUSESOC) run --no-export --target $(CHS_SIM_TARGET) --tool verilator --flag $(CHS_FUSESOC_FLAGS) --build epfl:cheshire:cheshire $(CHS_FUSESOC_ARGS) \
	 	--verilator_options="-j $(shell nproc)" --make_options="-j $(shell nproc)"  2>&1 | tee buildsim.log


chs-verilator-sim: chs-verilator-build $(CHS_TESTS_DIR)/$(CHS_FIRMWARE)
	$(FUSESOC) run --no-export --target $(CHS_SIM_TARGET) --tool verilator --flag $(CHS_FUSESOC_FLAGS) --run epfl:cheshire:cheshire \
		--LOG_LEVEL=$(LOG_LEVEL) \
		--BINARY=$(CHS_TESTS_DIR)/$(CHS_FIRMWARE) \
		--BOOTMODE=$(CHS_BOOT_MODE) \
		--MAX_CYCLES=$(CHS_MAX_CYCLES) \
		 $(CHS_FUSESOC_ARGS)
	cat $(CHS_ROOT)/logs/uart0.log

chs-verilator-run: $(CHS_TESTS_DIR)/$(CHS_FIRMWARE)
	$(FUSESOC) run --no-export --target $(CHS_SIM_TARGET) --tool verilator --flag $(CHS_FUSESOC_FLAGS) --run epfl:cheshire:cheshire \
		--LOG_LEVEL=$(LOG_LEVEL) \
		--BINARY=$(CHS_TESTS_DIR)/$(CHS_FIRMWARE) \
		--BOOTMODE=$(CHS_BOOT_MODE) \
		--MAX_CYCLES=$(CHS_MAX_CYCLES) \
		--trace=true \
		$(CHS_FUSESOC_ARGS)
	cat $(CHS_ROOT)/logs/uart0.log

chs-verilator-waves:
	gtkwave -f $(CHS_BUILD_DIR)/epfl_cheshire_cheshire_0.0.1/sim-verilator/waveform.fst -a $(CHS_ROOT)/tb/verilator/waves.gtkw


# -------------------
# QuestaSim - FuseSoC
# -------------------
FUSESOC_BUILD_DIR			     = $(shell find $(CHS_BUILD_DIR) -type d -name 'epfl_cheshire_cheshire_*' 2>/dev/null | sort | head -n 1)
QUESTA_SIM_DIR				     = $(FUSESOC_BUILD_DIR)/sim-modelsim
CHS_QUESTA_SIM_POSTSYNTH_DIR 	     = $(FUSESOC_BUILD_DIR)/sim_postsynthesis-modelsim

## Build simulation model
.PHONY: chs-questasim-build
chs-questasim-build: .check-fusesoc
	$(FUSESOC) run --no-export --target $(CHS_SIM_TARGET) --tool modelsim --flag $(CHS_FUSESOC_FLAGS) --build epfl:cheshire:cheshire $(CHS_FUSESOC_ARGS) \


# Build and launch simulation
.PHONY: chs-questasim-sim
chs-questasim-sim: .check-fusesoc chs-questasim-build $(FUSESOC_BUILD_DIR)/sim-modelsim/logs/
	$(FUSESOC) run --no-export --target $(CHS_SIM_TARGET) --tool modelsim --flag $(CHS_FUSESOC_FLAGS) --run epfl:cheshire:cheshire  \
		--PRELMODE=1 \
		--BINARY=$(CHS_TESTS_DIR)/$(CHS_FIRMWARE) \
		--BOOTMODE=0 \
		--vcd_mode=0 \
		$(CHS_FUSESOC_ARGS)

## Launch simulation
.PHONY: chs-questasim-run
chs-questasim-run:
	$(FUSESOC) run --no-export --target $(CHS_SIM_TARGET) --tool modelsim --flag $(CHS_FUSESOC_FLAGS) --run epfl:cheshire:cheshire  \
		--PRELMODE=1 \
		--BINARY=$(CHS_TESTS_DIR)/$(CHS_FIRMWARE) \
		--BOOTMODE=0 \
		--vcd_mode=0 \
		$(CHS_FUSESOC_ARGS)

.PHONY: chs-questasim-gui
chs-questasim-gui: $(QUESTA_SIM_DIR)/logs/
	$(MAKE) -C $(QUESTA_SIM_DIR) run-gui RUN_OPT=1 PLUSARGS="BINARY=$(CHS_TESTS_DIR)/$(CHS_FIRMWARE) BOOTMODE=0 PRELMODE=1 vcd_mode=0"




# -----------------
# Postsynthesis sim
# -----------------

.PHONY: chs-postsyn-build
chs-postsyn-build:
	$(FUSESOC) run --no-export --target sim_postsynthesis --tool modelsim --flag $(CHS_FUSESOC_FLAGS) --build  epfl:cheshire:cheshire \
		$(CHS_FUSESOC_ARGS);


## Questasim Postsynth run
.PHONY: chs-postsyn-run
chs-postsyn-run: | $(CHS_QUESTA_SIM_POSTSYNTH_DIR)/logs/
	$(FUSESOC) run --no-export --target sim_postsynthesis --tool modelsim --flag $(CHS_FUSESOC_FLAGS) --run epfl:cheshire:cheshire \
		--PRELMODE=0 \
		--BINARY=$(CHS_TESTS_DIR)/$(CHS_FIRMWARE) \
		--BOOTMODE=4 \
		--vcd_mode=$(CHS_VCD_MODE) \
		$(CHS_FUSESOC_ARGS)


.PHONY: chs-postsyn-gui
chs-postsyn-gui: $(CHS_QUESTA_SIM_POSTSYNTH_DIR)/logs/
	$(MAKE) -C $(CHS_QUESTA_SIM_POSTSYNTH_DIR) run-gui RUN_OPT=1 PLUSARGS="BINARY=$(CHS_TESTS_DIR)/$(CHS_FIRMWARE) BOOTMODE=4 PRELMODE=0 vcd_mode=$(CHS_VCD_MODE)"

## Profile
include $(CHS_ROOT)/util/profile/profile.mk


# ----------------
# Vivado - FuseSoC
# ----------------

## Synthesis for FPGA
# TODO
