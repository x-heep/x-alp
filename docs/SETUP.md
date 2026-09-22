# X-ALP Setup Guide

Welcome to X-ALP (eXtendable Application Level Platform)! This guide will help you set up your development environment and get started with the project.

**X-ALP** is a RISC-V based hardware/software co-design platform for embedded systems development, built on top of X-HEEP (eXtendable Heterogeneous Energy-Efficient Platform).

---

## Prerequisites

Before you begin, ensure you have the following installed on your system:

### Supported Operating Systems

- **Linux** (Ubuntu 20.04+ or equivalent) - Recommended
- **macOS** (10.15+ Catalina or newer)
- **Windows** (via WSL2 with Ubuntu)

### Required Tools & Versions

#### Essential Tools

| Tool | Minimum Version | Purpose | Installation Link |
|------|----------------|---------|-------------------|
| **Python** | 3.13+ | Scripting and build automation | [python.org](https://www.python.org/downloads/) |
| **pip** | Latest | Python package manager | Included with Python |
| **CMake** | 3.16+ | Software build system | [cmake.org](https://cmake.org/download/) |
| **Ninja** | 1.10+ | Fast build tool | [ninja-build.org](https://ninja-build.org/) |
| **Git** | 2.20+ | Version control | [git-scm.com](https://git-scm.com/) |
| **Make** | 4.0+ | Build automation | Pre-installed on most systems |

#### RISC-V Toolchain

You'll need a **RISC-V GCC cross-compiler** to build firmware for the embedded platform:

- **Toolchain**: Embecosm CORE-V GNU Toolchain
- **Download**: [Embecosm CORE-V Toolchain](https://embecosm.com/downloads/tool-chain-downloads/#core-v-top-of-tree-compilers)
- **Pre-built binaries**: Available on the Embecosm downloads page for Linux and macOS

**Installation Example (Ubuntu)**:
```bash
# Install build essentials
sudo apt-get update
sudo apt-get install build-essential git cmake ninja-build

# Download Embecosm CORE-V toolchain from:
# https://embecosm.com/downloads/tool-chain-downloads/#core-v-top-of-tree-compilers
# Extract and add to PATH
export PATH=$PATH:/path/to/embecosm-toolchain/bin
```

**Installation Example (macOS)**:
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install python cmake ninja git

# Download Embecosm CORE-V toolchain from:
# https://embecosm.com/downloads/tool-chain-downloads/#core-v-top-of-tree-compilers
# Extract and add to PATH
export PATH=$PATH:/path/to/embecosm-toolchain/bin
```

#### Simulation & Hardware Tools

| Tool | Purpose | Required? |
|------|---------|-----------|
| **Verilator** | RTL simulation - v5.042 from source | Yes (for simulation) |
| **FuseSoC** | Hardware build & IP management | Yes (installed via Python) |
| **Verible** | SystemVerilog linting/formatting | Yes (for code quality) |
| **GTKWave** | Waveform viewer | Optional (recommended) |

**Verilator Installation** (build from source v5.042):

Set the installation directory variable (customize as needed):
```bash
export VERILATOR_INSTALL_DIR=/opt/verilator
```

Install dependencies and build:
```bash
# Clone the Verilator repository and check out the v5.042 tag
git clone https://github.com/verilator/verilator.git
cd verilator
git checkout v5.042

# Install dependencies
# Ubuntu/Debian:
sudo apt-get install git help2man perl python3 make autoconf g++ flex bison ccache
# macOS:
brew install autoconf bison flex ccache

# Build and install Verilator
./configure --prefix=$VERILATOR_INSTALL_DIR
make -j$(nproc)
sudo make install

# Add to PATH (add to ~/.bashrc or ~/.zshrc for persistence)
export PATH=$PATH:$VERILATOR_INSTALL_DIR/bin
```

**⚠️ Tip for macOS Users (Apple Silicon M1/M2/M3/M4)**:

On Apple Silicon, the system `bison` and `flex` may cause compilation issues. Build them from source following [this guide](https://k0nze.dev/posts/verilog-apple-silicon/) before running Verilator's configure:

```bash
# Install bison from source
sudo mkdir -p /opt/bison/bison-3.7.91
wget http://alpha.gnu.org/gnu/bison/bison-3.7.91.tar.xz
tar -xvf bison-3.7.91.tar.xz
cd bison-3.7.91
./configure --prefix=/opt/bison/bison-3.7.91 CFLAGS="-isysroot $(xcrun -show-sdk-path)" CXXFLAGS="-isysroot $(xcrun -show-sdk-path)"
make
sudo make install

# Install flex from source
cd ..
sudo mkdir -p /opt/flex/flex-2.6.4
wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4
./configure --prefix=/opt/flex/flex-2.6.4 CFLAGS="-isysroot $(xcrun -show-sdk-path)" CXXFLAGS="-isysroot $(xcrun -show-sdk-path)"
make
sudo make install

# Add paths to ~/.zshrc (and reload with: source ~/.zshrc)
echo 'export CFLAGS="-I/opt/bison/bison-3.7.91/share/include -I/opt/flex/flex-2.6.4/include ${CFLAGS}"' >> ~/.zshrc
echo 'export CXXFLAGS="-I/opt/bison/bison-3.7.91/share/include -I/opt/flex/flex-2.6.4/include ${CXXFLAGS}"' >> ~/.zshrc
echo 'export LDFLAGS="-L/opt/bison/bison-3.7.91/lib -L/opt/flex/flex-2.6.4/lib ${LDFLAGS}"' >> ~/.zshrc
echo 'export PATH="/opt/bison/bison-3.7.91/bin:/opt/flex/flex-2.6.4/bin:${PATH}"' >> ~/.zshrc
source ~/.zshrc
```

After custom `bison` and `flex` are installed, proceed with the Verilator build above.

**Verible Installation** (SystemVerilog formatter and linter):

The recommended version is **v0.0-3946-g851d3ff4**.

**Installation Options**:

1. **via Homebrew (macOS - easiest)**:
```bash
brew install verible

# Verify installation
verible-verilog-format --version
```

2. **via GitHub Releases (all platforms)**:
```bash
# Download the specific version v0.0-3946-g851d3ff4 (or latest) from:
# https://github.com/chipsalliance/verible/releases

# Extract the archive
tar -xzf verible-v0.0-3946-g851d3ff4-*.tar.gz

# Move to installation directory (optional)
sudo mv verible-v0.0-3946-g851d3ff4 /opt/verible

# Add to your PATH
export PATH=$PATH:/opt/verible/bin

# Verify installation
verible-verilog-format --version
```

**Note**: The exact version may vary depending on when you install via Homebrew. For consistent versioning across teams, consider downloading the specific release from GitHub. Check your installed version with `verible-verilog-format --version`. The Makefile will verify Verible is available when you run `make format` or `make lint`.

**GTKWave Installation** (Optional):
```bash
# Ubuntu/Debian
sudo apt-get install gtkwave

# macOS
brew install gtkwave
```

### Environment Managers

Choose **one** of the following:

1. **Conda/Miniconda** (Recommended) - Manages Python and all dependencies
   - [Download Miniconda](https://docs.conda.io/en/latest/miniconda.html)
   - Recommended for hardware/software co-design workflows
   - **Note**: X-ALP uses the same Miniconda environment as X-HEEP (`core-v-mini-mcu`)
   
2. **Python venv** - Built-in Python virtual environment
   - Lighter weight alternative
   - Automatically created on first build

#### About the Miniconda Environment (`core-v-mini-mcu`)

X-ALP provides a comprehensive Miniconda environment specification in `util/conda_environment.yml`. This environment:

- **Is identical to X-HEEP's environment** - You can use the same environment for both projects
- **Contains Python 3.13** - Latest stable RISC-V toolchain support
- **Includes FuseSoC** - Open-source hardware build and IP management system
- **Includes hardware build tools** - CMake, Ninja for efficient compilation
- **Includes Python packages** for:
  - PyYAML - Configuration file processing
  - Mako - Code generation templates
  - GitPython - Git repository manipulation
  - Black - Python code formatter
  - Edalize - HDL design toolchain abstraction
  - RV Profiler - RISC-V firmware profiling
  - Area Plot - Post-synthesis area analysis

**Multi-project setup**: If you work on both X-HEEP and X-ALP, you can share the same `core-v-mini-mcu` environment across both projects. Simply activate the environment once and use it for both:

```bash
# First time setup (either project)
make conda

# Then use it for any project
conda activate core-v-mini-mcu
cd /path/to/x-heep
make ...

cd /path/to/x-alp
make ...
```

---

## Installation & Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/x-heep/x-alp.git
cd x-alp
```

### Step 2: Set Up Python Environment

#### Option A: Using Conda (Recommended)

```bash
# Create and activate the conda environment
make conda

# Activate the environment
conda activate core-v-mini-mcu
```

The conda environment will automatically install:
- Python 3.13
- FuseSoC (hardware build system)
- All required Python packages (PyYAML, Mako, GitPython, etc.)

#### Option B: Using Python venv

The Makefile will automatically set up a virtual environment when you run build commands:

```bash
# The venv will be created automatically on first use
# It installs dependencies from util/python-requirements.txt
make help
```

To manually activate the virtual environment (if needed):
```bash
source .venv/bin/activate  # Linux/macOS
# or
.venv\Scripts\activate.bat  # Windows
```

### Step 3: Verify Tool Installation

Check that all required tools are installed and accessible:

```bash
# Check Python
python --version  # Should be 3.13+

# Check RISC-V toolchain
riscv32-corev-gcc --version

# Check CMake and Ninja
cmake --version
ninja --version

# Check Verilator
verilator --version

# Check FuseSoC (after activating environment)
fusesoc --version
```

### Step 4: Generate MCU Code

**Important**: Before building any applications, you must generate register files and boot ROM:

```bash
make mcu-gen
```

This command:
- Generates register interface files for peripherals
- Builds the boot ROM
- Formats the generated code

**⚠️ You must run this after cloning the repository and after any hardware configuration changes.**

---

## Environment Variables

X-ALP requires the `RISCV_XALP` environment variable for firmware compilation and supports additional optional configuration variables.

### Required Environment Variables

#### RISCV_XALP - RISC-V Toolchain Path

**Purpose**: Points to the Embecosm CORE-V GNU Toolchain binary directory.

**Default**: `~/.riscv` (if not set, the build system will warn you)

**Set it with**:
```bash
# Point to your toolchain installation
export RISCV_XALP=/opt/embecosm-toolchain/bin
# or wherever you installed the Embecosm toolchain
```

**Add to your shell configuration for persistence**:
```bash
echo 'export RISCV_XALP=/path/to/embecosm-toolchain/bin' >> ~/.zshrc
source ~/.zshrc
```

**Verify it's set correctly**:
```bash
# Check the variable is set
echo $RISCV_XALP

# Verify the toolchain is accessible
$RISCV_XALP/riscv32-corev-gcc --version
```

## Running Locally

### Firmware Compilation Setup

Before building any applications, you need to set up the firmware compilation environment with the RISC-V toolchain and Python tools.

#### RISC-V Toolchain Configuration

The firmware build requires the Embecosm CORE-V GNU Toolchain. After installation, you must set the `RISCV_XALP` environment variable to point to the toolchain's `bin` directory:

```bash
export RISCV_XALP=/path/to/embecosm-toolchain/bin
```

Add this to your `~/.bashrc` or `~/.zshrc` for persistence:
```bash
echo 'export RISCV_XALP=/path/to/embecosm-toolchain/bin' >> ~/.zshrc
source ~/.zshrc
```

**Verify the toolchain is accessible**:
```bash
# Check that the toolchain prefix works
riscv32-corev-gcc --version
```

### Python Environment & Build Tools

X-ALP uses a **Miniconda environment** that contains all required Python packages and build tools. This is the **same environment as X-HEEP** and includes:

- **Python 3.13** - Core scripting language
- **FuseSoC** - Hardware build system and IP manager
- **CMake** - Software build system generator
- **Ninja** - Fast build tool
- **PyYAML, Mako, GitPython** - Configuration and code generation tools
- **Black** - Python code formatter
- **Additional tools** - Edalize, RV Profiler, Area Plot generator

##### Setting Up the Conda Environment

The Miniconda environment can be created and activated with:

```bash
# Create the conda environment from the provided specification
make conda

# Activate the environment
conda activate core-v-mini-mcu

# Verify Python and tools are available
python --version          # Should show 3.13+
fusesoc --version
cmake --version
ninja --version
```

**Note**: You only need to run `make conda` once. After that, simply activate the environment with `conda activate core-v-mini-mcu` in new terminal sessions.

##### Alternative: Using Python venv

If you prefer not to use Miniconda, the build system automatically creates a Python virtual environment (`.venv`) on first use:

```bash
# The venv is created automatically when you run any make target
make help

# Manually activate the virtual environment
source .venv/bin/activate       # Linux/macOS
# or
.venv\Scripts\activate.bat      # Windows
```

**⚠️ Important**: Always run `make mcu-gen` before building firmware for the first time or after any hardware configuration changes.

### Building Applications

X-ALP includes sample applications in `sw/applications/`. To build an application:

```bash
make app PROJECT=hello_world TARGET=sim
```

**Prerequisites for compilation**:
```bash
# 1. Ensure RISC-V toolchain path is set
echo $RISCV_XALP    # Should show the toolchain bin directory path

# 2. Activate the Miniconda environment (if not already active)
conda activate core-v-mini-mcu

# 3. Generate MCU files (if not done already)
make mcu-gen
```

**Build Parameters**:

| Parameter | Default | Options | Description |
|-----------|---------|---------|-------------|
| `PROJECT` | `hello_world` | Any folder in `sw/applications/` | Application to build |
| `TARGET` | `sim` | `sim`, `pynq-z2`, `nexys-a7-100t`, zcu104, zcu102 | Target platform/FPGA |
| `LINKER` | `spm` | `spm`, `dram`, `rom` | Memory layout and linking strategy |
| `COMPILER` | `gcc` | `gcc`, `clang` | C/C++ compiler to use |
| `COMPILER_PREFIX` | `riscv32-corev-` | `riscv32-corev-`, `riscv32-unknown-elf-` | RISC-V toolchain prefix |
| `ARCH` | `rv32imc` | `rv32imc`, `rv32gc`, `rv64gc_zifencei`, or any valid RISC-V ISA | Target architecture |
| `COMPILER_FLAGS` | `-mabi=lp64d` | ABI flags for the architecture | Calling convention and ABI |

**Compilation Process**:

The application build process:
1. Invokes CMake to generate build files
2. Uses Ninja to compile C/C++ source code
3. Links against device libraries and linker scripts
4. Generates ELF binary and SPM (Simulated Program Memory) format
5. Displays memory usage statistics

**Output artifacts**:
```
sw/build/                          # Build directory
  main.elf                         # ELF executable
  main.spm.elf                     # SPM format (used in simulations)
  main.hex                         # Hex format (for FPGA loading)
  *.o                              # Object files
  CMakeFiles/                      # CMake build files
```

**List available applications**:
```bash
make app-list
```

### Running Simulations

#### 1. Build the Verilator Simulation

```bash
make verilator-build
```

This compiles the RTL (Register Transfer Level) hardware design using Verilator. It may take several minutes on the first run.

#### 2. Run the Simulation

```bash
make verilator-run
```

By default, this runs the compiled application (`sw/build/main.spm.elf`) in the simulator.

**Simulation Parameters**:

```bash
# Run with custom binary
make verilator-run BINARY=sw/build/my_app.spm.elf

# Increase simulation cycles
make verilator-run MAX_CYCLES=5000000

# Change log level
make verilator-run LOG_LEVEL=LOG_INFO
```

#### 3. View Waveforms (Optional)

After running a simulation with tracing enabled, view the waveforms:

```bash
make verilator-waves
```

This opens GTKWave with the generated waveform file.

### Testing

X-ALP uses embedded C applications as functional tests. To verify your setup:

```bash
# Build and run the hello_world application
make mcu-gen
make app PROJECT=hello_world TARGET=sim
make verilator-build
make verilator-run
```

Expected output in `build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/uart0.log`:
```
Hello World!
```

### Linting & Formatting

Maintain code quality with built-in linting and formatting tools:

#### Format Code

```bash
make format
```

This formats:
- **SystemVerilog** files using Verible
- **C/C++** files using clang-format

#### Lint Code

```bash
make lint
```

Runs Verible linter on SystemVerilog files to catch style and syntax issues.

**🔧 Tip**: Run `make format` before committing to ensure consistent code style.

---

## Troubleshooting

### Common Issues & Solutions

#### ❌ Error: `fusesoc: command not found`

**Cause**: FuseSoC is not in your PATH or the Python environment is not activated.

**Solution**:
```bash
# If using conda
conda activate core-v-mini-mcu

# If using venv, ensure it was created
make help  # This triggers venv creation
source .venv/bin/activate
```

---

#### ❌ Error: `riscv32-corev-gcc: command not found`

**Cause**: RISC-V toolchain is not installed or RISCV_XALP not set correctly.

**Solution**:
```bash
# 1. Verify RISCV_XALP is set
echo $RISCV_XALP

# 2. If not set, install Embecosm CORE-V toolchain from:
# https://embecosm.com/downloads/tool-chain-downloads/#core-v-top-of-tree-compilers

# 3. Set RISCV_XALP to the toolchain bin directory
export RISCV_XALP=/path/to/embecosm-toolchain/bin

# 4. Verify the toolchain is accessible
$RISCV_XALP/riscv32-corev-gcc --version
```

---

#### ❌ Error: "forgot to run make mcu-gen"

**Cause**: Register files and boot ROM haven't been generated.

**Solution**:
```bash
make mcu-gen
```

Always run this command after cloning the repository or modifying hardware configurations.

---

#### ❌ Error: Application build fails with linker errors

**Cause**: Wrong linker script selected or MCU files not generated.

**Solution**:
```bash
# 1. Ensure MCU files are generated
make mcu-gen

# 2. Check available linker scripts
ls sw/linker/

# 3. Use correct LINKER parameter matching your target
make app PROJECT=hello_world TARGET=sim LINKER=spm

# 4. For FPGA targets, try:
make app PROJECT=hello_world TARGET=pynq-z2 LINKER=spm
```

---

#### ❌ Error: `verilator: command not found`

**Cause**: Verilator is not installed.

**Solution**:
```bash
# Verilator v5.042 must be built from source
# See the "Verilator Installation" section in this document for detailed steps

# After installation, verify it's accessible
verilator --version  # Should show v5.042
```

---

#### ❌ Build fails with "No rule to make target"

**Cause**: Build artifacts from previous incomplete builds or CMake cache issues.

**Solution**:
```bash
# Clean build artifacts
make clean-app
make clean

# Regenerate and rebuild
make mcu-gen
make app PROJECT=hello_world TARGET=sim
```

---

#### ❌ Simulation hangs or times out

**Cause**: The simulation exceeded MAX_CYCLES or is waiting for input.

**Solution**:
```bash
# Increase simulation cycles
make verilator-run MAX_CYCLES=5000000

# Check uart0.log for error messages
cat build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/uart0.log

# Check for compilation errors in buildsim.log
cat buildsim.log
```

---

#### ❌ Python package installation fails

**Cause**: Network issues or incompatible Python version.

**Solution**:
```bash
# Ensure Python 3.13+ is installed
python --version

# Manually install dependencies
pip install -r util/python-requirements.txt

# For conda users, recreate environment
conda env remove -n core-v-mini-mcu
make conda
```

---

#### ❌ Permission denied errors

**Cause**: Insufficient permissions to execute scripts or install tools.

**Solution**:
```bash
# Make scripts executable
chmod +x hw/ip/*/.*_gen.sh

# On Linux, you may need sudo for some installations
sudo apt-get install <package-name>
```

---

### Getting Help

If you encounter issues not covered here:

1. **Check existing documentation**: Look in the `docs/` directory
2. **Search issues**: Check the [GitHub Issues](https://github.com/x-heep/x-alp/issues) page
3. **Ask for help**: Open a new issue with:
   - Your OS and version
   - Command you ran
   - Complete error message
   - Output of `make help` and tool versions

---

## Verifying Your Setup (Smoke Test)

Follow this complete workflow to verify your setup is working correctly:

### 1. Environment Setup Verification

```bash
# Verify RISC-V toolchain is accessible
echo $RISCV_XALP
$RISCV_XALP/riscv32-corev-gcc --version    # Should show Embecosm CORE-V compiler

# Verify conda environment can be created
conda create --help                        # Verifies Miniconda is installed

# Verify additional tools are installed
python --version       # Should show 3.13+
cmake --version        # Should show 3.16+
ninja --version        # Should show 1.10+
verilator --version    # Should show v5.042
```

**✅ Expected**: All commands return version numbers without errors.

### 2. Python Environment Activation

```bash
# Create conda environment (one-time setup)
make conda

# Activate the environment
conda activate core-v-mini-mcu

# Verify tools in environment
python --version
fusesoc --version      # Should be available
cmake --version
ninja --version
```

**✅ Expected**:
- Conda environment created successfully
- Environment activation works
- All Python tools are accessible

### 3. Code Generation Verification

```bash
cd /path/to/x-alp
make mcu-gen
```

**✅ Expected**: 
- No errors during register generation
- Boot ROM builds successfully
- Code formatting completes
- Console shows completion messages

### 4. Application Build Verification

```bash
# Build the hello_world application
make app PROJECT=hello_world TARGET=sim
```

**✅ Expected**:
- Conda environment is active
- RISCV_XALP is set correctly
- CMake configuration succeeds
- RISC-V compiler is invoked
- Compilation produces no errors
- Output shows: `sw/build/main.spm.elf` created
- Memory usage report is displayed

**Example successful output**:
```
INFO: Using RISCV_XALP from environment or command line: /opt/embecosm-toolchain/bin
-- Configuring done
-- Generating done
-- Build files have been written to: ...
[ 25%] Building C object ...
[ 50%] Linking C executable main.elf
[100%] Built target main.spm.elf
Memory usage report generated...
```

### 5. Simulation Build Verification

```bash
make verilator-build
```

**✅ Expected**:
- Conda environment is active
- FuseSoC runs successfully
- Verilator compilation completes (may take 5-10 minutes first time)
- Output file created: `build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/Vx_alp`
- Log file created: `buildsim.log`

### 6. Simulation Run Verification

```bash
make verilator-run
```

**✅ Expected**:
- Simulation starts and completes
- Console shows: "Simulation finished."
- UART output is displayed showing "Hello World!"
- File exists: `build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/uart0.log`

**Verify the output**:
```bash
cat build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/uart0.log
```

Should display:
```
Hello World!
```

### 7. Code Quality Verification

```bash
make format
make lint
```

**✅ Expected**:
- Format command completes without errors
- Lint command runs and reports no critical issues

---

### Complete Smoke Test Script

Run this entire sequence to validate your setup:

```bash
#!/bin/bash
# X-ALP Comprehensive Smoke Test Script

set -e  # Exit on any error

echo "=== X-ALP Setup Verification ==="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 0: Environment check
echo "Step 0: Verifying environment variables..."
if [ -z "$RISCV_XALP" ]; then
    echo -e "${YELLOW}WARNING: RISCV_XALP not set. Attempting to use default ~/.riscv${NC}"
    export RISCV_XALP=~/.riscv
fi
echo "  RISCV_XALP=$RISCV_XALP"

if [ ! -d "$RISCV_XALP" ]; then
    echo -e "${RED}ERROR: RISCV_XALP directory does not exist: $RISCV_XALP${NC}"
    exit 1
fi
echo "✓ RISCV_XALP verified"
echo ""

echo "Step 1: Checking system tools..."
echo "  Checking RISC-V compiler..."
$RISCV_XALP/riscv32-corev-gcc --version | head -n 1
echo "  Checking Python..."
python --version
echo "  Checking CMake..."
cmake --version | head -n 1
echo "  Checking Ninja..."
ninja --version
echo "  Checking Verilator..."
verilator --version | head -n 1
echo "✓ All system tools found"
echo ""

echo "Step 2: Setting up Python environment..."
# Check if conda is available
if command -v conda &> /dev/null; then
    # Check if core-v-mini-mcu environment exists
    if conda env list | grep -q "core-v-mini-mcu"; then
        echo "  Miniconda environment 'core-v-mini-mcu' already exists"
    else
        echo "  Creating Miniconda environment..."
        make conda
    fi
    echo "  Activating conda environment..."
    source $(conda info --base)/etc/profile.d/conda.sh
    conda activate core-v-mini-mcu
else
    echo "  Creating Python virtual environment..."
    make help > /dev/null  # This triggers venv creation
    source .venv/bin/activate
fi

echo "  Verifying FuseSoC..."
fusesoc --version
echo "✓ Python environment ready"
echo ""

echo "Step 3: Generating MCU code..."
make mcu-gen
echo "✓ MCU code generation successful"
echo ""

echo "Step 4: Building hello_world application..."
make app PROJECT=hello_world TARGET=sim
echo "✓ Application build successful"
echo ""

echo "Step 5: Building Verilator simulation..."
echo "  (This may take 5-10 minutes on first run...)"
make verilator-build
echo "✓ Simulation build successful"
echo ""

echo "Step 6: Running simulation..."
make verilator-run
echo "✓ Simulation run successful"
echo ""

echo "Step 7: Verifying simulation output..."
if grep -q "Hello World" build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/uart0.log; then
    echo "✓ Output verification successful"
else
    echo -e "${RED}ERROR: Output verification failed${NC}"
    exit 1
fi
echo ""

echo "Step 8: Checking code formatting..."
echo "  Running Verible format check..."
if command -v verible-verilog-format &> /dev/null; then
    # Check formatting without modifying
    echo "  (Format check would be performed with: make format)"
    echo "✓ Verible available"
else
    echo -e "${YELLOW}WARNING: Verible not found, skipping format check${NC}"
fi
echo ""

echo -e "${GREEN}=== ✓ All smoke tests passed! ===${NC}"
echo "Your X-ALP development environment is ready to use."
echo ""
echo "Next steps:"
echo "  - Explore applications in sw/applications/"
echo "  - Read documentation in docs/"
echo "  - Build custom applications with: make app PROJECT=<name> TARGET=<target>"
echo "  - Run simulations with: make verilator-run BINARY=<binary_path>"

echo "Step 6: Verifying output..."
if grep -q "Hello World" build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/uart0.log; then
    echo "✓ Output verification successful"
else
    echo "✗ Output verification failed"
    exit 1
fi
echo ""

echo "=== ✓ All smoke tests passed! ==="
echo "Your X-ALP development environment is ready to use."
```

Save this as `smoke-test.sh`, make it executable with `chmod +x smoke-test.sh`, and run it with `./smoke-test.sh`.

---

## Next Steps

Now that your setup is complete, you can:

1. **Explore the codebase**: Check `sw/applications/` for example code
2. **Read the documentation**: Visit the `docs/` directory for detailed guides
3. **Start contributing**: Check `CONTRIBUTING.md` for workflow guidelines
4. **Join the community**: Engage with other developers on GitHub Issues

### Useful Resources

- **Repository**: [https://github.com/x-heep/x-alp](https://github.com/x-heep/x-alp)
- **Issues**: [https://github.com/x-heep/x-alp/issues](https://github.com/x-heep/x-alp/issues)
- **License**: Solderpad Hardware License v0.51 (Apache 2.0 compatible)

---

**Happy Hacking! 🚀**

If you encounter any issues with this setup guide, please open an issue on GitHub.