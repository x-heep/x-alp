# Setup

This page explains how to install the tools needed to generate X-ALP, compile software for it and simulate it. X-ALP uses the same tools as [X-HEEP](https://x-heep.readthedocs.io/en/latest/GettingStarted/Setup.html), so an environment set up for X-HEEP also works for X-ALP.

## Supported operating systems

- **Linux**: Ubuntu 22.04 or 24.04 recommended.
- **macOS**: supported; see the Apple Silicon notes in the [Verilator](#4-install-verilator) section.
- **Windows**: through WSL2 with Ubuntu.

## Docker setup

The CI of X-ALP runs inside the X-HEEP toolchain image, available on [GitHub Packages](https://ghcr.io/x-heep/x-heep/x-heep-toolchain). It already contains the RISC-V toolchain (in `/tools/riscv`, exported as `RISCV_XHEEP`), Verilator, Verible and the Python packages. To use it, [install Docker](https://docs.docker.com/engine/install/) and mount your X-ALP clone:

```bash
docker run -it -v $(pwd):/workspace/x-alp ghcr.io/x-heep/x-heep/x-heep-toolchain:latest
cd /workspace/x-alp
export RISCV_XALP=$RISCV_XHEEP
```

Then continue with [Generating the platform](./GeneratingMCU.md).

## Manual setup

### 1. OS requirements

On Ubuntu, the following command installs the build dependencies of the tools below:

```bash
sudo apt install autoconf automake autotools-dev curl python3 python3-pip libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build git cmake libglib2.0-dev help2man perl make g++ libfl2 libfl-dev ccache libgoogle-perftools-dev numactl libelf-dev pkg-config tree clang-format gtkwave
```

On macOS, install the equivalent packages with [Homebrew](https://brew.sh/):

```bash
brew install python cmake ninja git autoconf bison flex ccache tree clang-format
```

The required tools are:

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3 (see `util/conda_environment.yml`) | Platform generation and build scripts |
| CMake | 3.15+ | Firmware build system |
| Make | 4.0+ | Top-level flow |
| Git | 2.20+ | Version control and vendoring |
| RISC-V toolchain | Embecosm CORE-V GCC | Firmware compilation |
| Verilator | 5.042 | RTL simulation |
| Verible | v0.0-3946-g851d3ff4 | SystemVerilog formatting and linting |
| FuseSoC | x-heep fork, installed with the Python packages | Hardware build and IP management |
| GTKWave | any | Waveform viewer (optional) |

### 2. Python

X-ALP relies on either (a) Miniconda or (b) a Python virtual environment. Choose one of them.

#### 2.a Miniconda (recommended)

Install [Miniconda](https://docs.conda.io/en/latest/miniconda.html), then create the environment from the X-ALP root folder:

```bash
make conda
```

This creates the `core-v-mini-mcu` environment from `util/conda_environment.yml`, including FuseSoC, Edalize, Mako, PyYAML and the documentation packages. It is the same environment used by X-HEEP, so you can share it between the two projects. You only need to create it once; then activate it every time you work with X-ALP:

```bash
conda activate core-v-mini-mcu
```

#### 2.b Virtual environment

If no conda environment is active, the Makefile automatically creates a virtual environment in `.venv` the first time a target needs Python, installing `util/python-requirements.txt` and `docs/python-requirements.txt`. You can also create it explicitly and activate it:

```bash
make venv
source .venv/bin/activate
```

### 3. Install the RISC-V compiler

X-ALP firmware is compiled with the [CORE-V toolchain from Embecosm](https://embecosm.com/downloads/tool-chain-downloads/#core-v-top-of-tree-compilers), which is the default toolchain of the compilation flow (`COMPILER_PREFIX=riscv32-corev-`). Download a pre-built release for your OS and extract it, for example in `/home/$USER/tools/corev`.

Then set the `RISCV_XALP` environment variable to the toolchain **root folder** (the one that contains `bin/`, without `/bin`):

```bash
export RISCV_XALP=/home/$USER/tools/corev
```

Add this line to your `~/.bashrc` or `~/.zshrc` so that it is set automatically. Check that the compiler is found:

```bash
$RISCV_XALP/bin/riscv32-corev-elf-gcc --version
```

```{warning}
X-ALP uses `RISCV_XALP`, not `RISCV_XHEEP` or `RISCV`. If `RISCV_XALP` is not set, the build falls back to `~/.riscv` and prints a warning.
```

Optionally, you can also compile with Clang/LLVM (`COMPILER=clang`). Install Clang and LLD in the same `RISCV_XALP` folder, as described in the [X-HEEP setup guide](https://x-heep.readthedocs.io/en/latest/GettingStarted/Setup.html#install-the-risc-v-compiler).

### 4. Install Verilator

X-ALP is simulated with Verilator 5.042, built from source:

```bash
export VERILATOR_VERSION=5.042

git clone https://github.com/verilator/verilator.git
cd verilator
git checkout v$VERILATOR_VERSION

autoconf
./configure --prefix=/home/$USER/tools/verilator/$VERILATOR_VERSION
make -j$(nproc)
make install
```

Then add Verilator to your `PATH`, also in your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH=/home/$USER/tools/verilator/$VERILATOR_VERSION/bin:$PATH
```

````{tip}
On Apple Silicon, the system `bison` and `flex` may break the Verilator build. Build them from source (see [this guide](https://k0nze.dev/posts/verilog-apple-silicon/)) before running Verilator's `configure`:

```bash
# bison
sudo mkdir -p /opt/bison/bison-3.7.91
wget http://alpha.gnu.org/gnu/bison/bison-3.7.91.tar.xz
tar -xvf bison-3.7.91.tar.xz
cd bison-3.7.91
./configure --prefix=/opt/bison/bison-3.7.91 CFLAGS="-isysroot $(xcrun -show-sdk-path)" CXXFLAGS="-isysroot $(xcrun -show-sdk-path)"
make && sudo make install
cd ..

# flex
sudo mkdir -p /opt/flex/flex-2.6.4
wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4
./configure --prefix=/opt/flex/flex-2.6.4 CFLAGS="-isysroot $(xcrun -show-sdk-path)" CXXFLAGS="-isysroot $(xcrun -show-sdk-path)"
make && sudo make install

# Use them (add these lines to ~/.zshrc)
export CFLAGS="-I/opt/bison/bison-3.7.91/share/include -I/opt/flex/flex-2.6.4/include ${CFLAGS}"
export CXXFLAGS="-I/opt/bison/bison-3.7.91/share/include -I/opt/flex/flex-2.6.4/include ${CXXFLAGS}"
export LDFLAGS="-L/opt/bison/bison-3.7.91/lib -L/opt/flex/flex-2.6.4/lib ${LDFLAGS}"
export PATH="/opt/bison/bison-3.7.91/bin:/opt/flex/flex-2.6.4/bin:${PATH}"
```
````

### 5. Install Verible

SystemVerilog files are formatted and linted with [Verible](https://github.com/chipsalliance/verible). The recommended version is `v0.0-3946-g851d3ff4`. Download it from the [releases page](https://github.com/chipsalliance/verible/releases) and add it to your `PATH`:

```bash
export VERIBLE_VERSION=v0.0-3946-g851d3ff4
wget https://github.com/chipsalliance/verible/releases/download/${VERIBLE_VERSION}/verible-${VERIBLE_VERSION}-linux-static-x86_64.tar.gz
tar -xf verible-${VERIBLE_VERSION}-linux-static-x86_64.tar.gz
mkdir -p /home/$USER/tools/verible/${VERIBLE_VERSION}/
mv verible-${VERIBLE_VERSION}/* /home/$USER/tools/verible/${VERIBLE_VERSION}/
export PATH=/home/$USER/tools/verible/${VERIBLE_VERSION}/bin:$PATH
```

On macOS, `brew install verible` also works, although Homebrew may install a different version. Check it with `verible-verilog-format --version`.

```{note}
`make mcu-gen` and `make verilator-build` run `make format`, which needs both `verible-verilog-format` and `clang-format` on the `PATH`.
```

### 6. Install GTKWave (optional)

[GTKWave](https://gtkwave.sourceforge.net/) is used by `make verilator-waves` to open the simulation waveforms (`sudo apt install gtkwave` or `brew install gtkwave`).

## Checking the installation

```bash
conda activate core-v-mini-mcu       # or: source .venv/bin/activate
echo $RISCV_XALP
$RISCV_XALP/bin/riscv32-corev-elf-gcc --version
cmake --version
verilator --version                   # Verilator 5.042
verible-verilog-format --version
fusesoc --version
```

If all commands print a version, continue with [Generating the platform](./GeneratingMCU.md).

## Troubleshooting

`fusesoc: command not found`
: The Python environment is not active. Run `conda activate core-v-mini-mcu`, or `make venv` and `source .venv/bin/activate`.

`riscv32-corev-elf-gcc: command not found` or `RISCV_XALP not set` warning
: Install the CORE-V toolchain and set `RISCV_XALP` to its root folder (without `/bin`).

`Hmmm... seems like the compilation failed...`
: Usually the platform files were not generated (run `make mcu-gen`) or the compiler parameters are wrong (see [Compiling applications](../How_to/CompileApps.md)).

`verilator: command not found`
: Add the Verilator `bin` folder to your `PATH`.

Simulation ends with `Simulation ended without exit signal`
: The application did not finish within `MAX_CYCLES` cycles. Increase it, for example `make verilator-run MAX_CYCLES=5000000`.

If your problem is not listed here, check the [GitHub issues](https://github.com/x-heep/x-alp/issues) or open a new one with your OS, the command you ran and the full error message.
