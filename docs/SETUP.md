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

- **Recommended**: RISC-V GNU Toolchain with `riscv32-corev-` prefix
- **Alternative**: `riscv32-unknown-elf-` toolchain
- **Download**: [RISC-V GNU Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain)
- **Pre-built binaries**: Check [releases page](https://github.com/riscv-collab/riscv-gnu-toolchain/releases) or use package managers

**Installation Example (Ubuntu)**:
```bash
# Install build essentials
sudo apt-get update
sudo apt-get install build-essential git cmake ninja-build

# Install RISC-V toolchain (example using apt)
sudo apt-get install gcc-riscv64-unknown-elf

# Or download pre-built toolchain and add to PATH
# export PATH=$PATH:/path/to/riscv-toolchain/bin
```

**Installation Example (macOS)**:
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install python cmake ninja git

# Install RISC-V toolchain
brew tap riscv-software-src/riscv
brew install riscv-tools
```

#### Simulation & Hardware Tools

| Tool | Purpose | Required? |
|------|---------|-----------|
| **Verilator** | RTL simulation | Yes (for simulation) |
| **FuseSoC** | Hardware build & IP management | Yes (installed via Python) |
| **Verible** | SystemVerilog linting/formatting | Yes (for code quality) |
| **GTKWave** | Waveform viewer | Optional (recommended) |

**Verilator Installation**:
```bash
# Ubuntu/Debian
sudo apt-get install verilator

# macOS
brew install verilator
```

**Verible Installation**:
```bash
# Download from GitHub releases
# https://github.com/chipsalliance/verible/releases
# Add to your PATH after extraction
```

**GTKWave Installation** (Optional):
```bash
# Ubuntu/Debian
sudo apt-get install gtkwave

# macOS
brew install gtkwave
```

### Environment Managers

Choose **one** of the following:

1. **Conda/Miniconda** (Recommended) - Manages Python and dependencies
   - [Download Miniconda](https://docs.conda.io/en/latest/miniconda.html)
2. **Python venv** - Built-in Python virtual environment

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
# or
riscv32-unknown-elf-gcc --version

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

X-ALP uses sensible defaults and doesn't require environment variables for basic operation. However, you can customize the build process using these optional variables:

### Optional Build Configuration

You can set these in your shell or pass them to `make` commands:

```bash
# Customize the RISC-V toolchain prefix
export COMPILER_PREFIX=riscv32-unknown-elf-

# Customize the target architecture
export ARCH=rv32imc

# Add the RISC-V toolchain to your PATH if not in a standard location
export PATH=$PATH:/path/to/riscv-toolchain/bin
```

### Making Variables Persistent

To avoid setting these every time, add them to your shell configuration file:

```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'export PATH=$PATH:/path/to/riscv-toolchain/bin' >> ~/.bashrc
source ~/.bashrc
```

**🔒 Security Note**: Never commit credentials, API keys, or sensitive information to the repository. If you need to use sensitive environment variables for development, create a `.env` file locally and add it to `.gitignore`.

---

## Running Locally

### Building Applications

X-ALP includes sample applications in `sw/applications/`. To build an application:

```bash
make app PROJECT=hello_world TARGET=sim
```

**Build Parameters**:

| Parameter | Default | Options | Description |
|-----------|---------|---------|-------------|
| `PROJECT` | `hello_world` | Any folder in `sw/applications/` | Application to build |
| `TARGET` | `sim` | `sim`, `pynq-z2`, `nexys-a7-100t`, etc. | Target platform |
| `LINKER` | `on_chip` | `on_chip`, `flash_load`, `flash_exec` | Linker script |
| `COMPILER` | `gcc` | `gcc`, `clang` | Compiler to use |
| `ARCH` | `rv32imc` | Any RISC-V ISA string | Target architecture |

**Example - Build with custom architecture**:
```bash
make app PROJECT=hello_world TARGET=sim ARCH=rv32gc
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

**Cause**: RISC-V toolchain is not installed or not in PATH.

**Solution**:
```bash
# Check if alternative prefix works
make app COMPILER_PREFIX=riscv32-unknown-elf-

# Or install the toolchain and add to PATH
export PATH=$PATH:/path/to/riscv-toolchain/bin
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

#### ❌ Error: `verilator: command not found`

**Cause**: Verilator is not installed.

**Solution**:
```bash
# Ubuntu/Debian
sudo apt-get install verilator

# macOS
brew install verilator
```

---

#### ❌ Build fails with "No rule to make target"

**Cause**: Build artifacts from previous incomplete builds.

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
# Verify tools are installed
python --version       # Should show 3.13+
cmake --version        # Should show 3.16+
ninja --version        # Should show 1.10+
verilator --version    # Should show installed version
fusesoc --version      # Should work after activating environment
```

**✅ Expected**: All commands return version numbers without errors.

### 2. Code Generation Verification

```bash
cd /path/to/x-alp
make mcu-gen
```

**✅ Expected**: 
- No errors during register generation
- Boot ROM builds successfully
- Code formatting completes
- Console shows: "Register generation complete"

### 3. Application Build Verification

```bash
make app PROJECT=hello_world TARGET=sim
```

**✅ Expected**:
- CMake configuration succeeds
- Compilation produces no errors
- Output shows: `sw/build/main.spm.elf` created
- Memory usage report is displayed

### 4. Simulation Build Verification

```bash
make verilator-build
```

**✅ Expected**:
- FuseSoC runs successfully
- Verilator compilation completes (may take 5-10 minutes first time)
- Output file created: `build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/Vx_alp`
- Log file created: `buildsim.log`

### 5. Simulation Run Verification

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

### 6. Code Quality Verification

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
# X-ALP Smoke Test Script

set -e  # Exit on any error

echo "=== X-ALP Setup Verification ==="
echo ""

echo "Step 1: Checking tools..."
python --version
cmake --version
ninja --version
verilator --version
fusesoc --version
echo "✓ All tools found"
echo ""

echo "Step 2: Generating MCU code..."
make mcu-gen
echo "✓ MCU code generation successful"
echo ""

echo "Step 3: Building hello_world application..."
make app PROJECT=hello_world TARGET=sim
echo "✓ Application build successful"
echo ""

echo "Step 4: Building Verilator simulation..."
make verilator-build
echo "✓ Simulation build successful"
echo ""

echo "Step 5: Running simulation..."
make verilator-run
echo "✓ Simulation run successful"
echo ""

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
3. **Start contributing**: Check `CONTRIBUTING.md` for workflow guidelines (if available)
4. **Join the community**: Engage with other developers on GitHub Issues

### Useful Resources

- **Repository**: [https://github.com/x-heep/x-alp](https://github.com/x-heep/x-alp)
- **Issues**: [https://github.com/x-heep/x-alp/issues](https://github.com/x-heep/x-alp/issues)
- **License**: Solderpad Hardware License v0.51 (Apache 2.0 compatible)

---

**Happy Hacking! 🚀**

If you encounter any issues with this setup guide, please open an issue on GitHub.
