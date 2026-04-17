# Tools
FUSESOC := python3 run_fusesoc.py
CORE_NAME := xheep:ip:power_manager

# Directories
BUILD_DIR := build

.PHONY: build sim clean generate

# 1. GENERATE
generate:
	@echo "## Generating RTL..."
	chmod +x power_manager_gen.sh
	./power_manager_gen.sh

# 2. BUILD
build: generate
	@echo "## Building Simulation Model..."
	$(FUSESOC) library add pulp_platform_register_interface hw/vendor/pulp_platform_register_interface
	$(FUSESOC) library add pulp_platform_common_cells hw/vendor/pulp_platform_common_cells
	$(FUSESOC) library add lowrisc_opentitan hw/vendor/lowrisc_opentitan
	$(FUSESOC) library add power_manager .
	$(FUSESOC) run --target=sim --setup --build $(CORE_NAME)

# 3. RUN
sim: build
	@echo "## Running Simulation..."
	$(FUSESOC) run --target=sim --run $(CORE_NAME)

clean:
	@echo "## Cleaning..."
	rm -rf build
	rm -f fusesoc.conf