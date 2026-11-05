#!/usr/bin/env bash

set -e

# Check arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <main-name.elf>"
    echo "Example: $0 main.spm.elf"
    exit 1
fi

# Configure the environment
source /eda/Xilinx/Vivado/2024.2/settings64.sh
export RISCV_XALP="/home/$USER/tools/risc-v"

# Initialize Conda
source /opt/miniconda3/etc/profile.d/conda.sh
conda activate core-v-mini-mcu

# Configure paths
ELF_FILE="$(realpath "sw/build/$1")"
OPENOCD_CFG="$(realpath "tb/core-v-mcu-xheep-programmer.cfg")"
GDB_BIN="$RISCV_XALP/bin/riscv32-corev-elf-gdb"

# Check that the ELF file exists
if [ ! -f "$ELF_FILE" ]; then
    echo "Error: ELF file not found: sw/build/$1"
    exit 1
fi

# Check that the OpenOCD configuration exists
if [ ! -f "$OPENOCD_CFG" ]; then
    echo "Error: OpenOCD configuration not found: tb/core-v-mcu-xheep-programmer.cfg"
    exit 1
fi

# Check that GDB exists
if [ ! -x "$GDB_BIN" ]; then
    echo "Error: GDB executable not found: $GDB_BIN"
    exit 1
fi

# Check tmux
if ! command -v tmux >/dev/null 2>&1; then
    echo "Error: tmux is not installed."
    exit 1
fi

# Configure the tmux session
SESSION="xalp-debug"

# Prevent duplicate sessions
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "Error: tmux session '$SESSION' already exists."
    echo "Attach with: tmux attach -t $SESSION"
    echo "Terminate with: tmux kill-session -t $SESSION"
    exit 1
fi

# Start OpenOCD in the left pane
tmux new-session -d -s "$SESSION" -n debug \
    "source /eda/Xilinx/Vivado/2024.2/settings64.sh; export RISCV_XALP='$RISCV_XALP'; source /opt/miniconda3/etc/profile.d/conda.sh; conda activate core-v-mini-mcu; openocd -f '$OPENOCD_CFG'; exec bash"

# Start GDB in the right pane
tmux split-window -h -t "$SESSION:debug" \
    "source /eda/Xilinx/Vivado/2024.2/settings64.sh; export RISCV_XALP='$RISCV_XALP'; source /opt/miniconda3/etc/profile.d/conda.sh; conda activate core-v-mini-mcu; '$GDB_BIN' '$ELF_FILE'; exec bash"

# Configure pane layout
tmux select-layout -t "$SESSION:debug" even-horizontal

# Focus the GDB pane
tmux select-pane -t "$SESSION:debug".1

# Attach to the debug session
env -u TMUX tmux attach-session -t "$SESSION"
