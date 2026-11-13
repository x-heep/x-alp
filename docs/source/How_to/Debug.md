# Debug

X-ALP includes the RISC-V debug module, accessible through JTAG. In simulation, the JTAG port is driven by a remote bitbang server (`tb/src/remote_bitbang`), compiled into the Verilator model through DPI. OpenOCD connects to this server, and GDB connects to OpenOCD.

## Prerequisites

1. The RISC-V GDB of your toolchain, e.g. `$RISCV_XALP/bin/riscv32-corev-elf-gdb`.
2. [OpenOCD](https://openocd.org/) with the remote bitbang driver enabled. Download a recent release (the configuration in `tb/core-v-mini-mcu.cfg` uses the RISC-V commands of OpenOCD 0.12) and build it:

```bash
./configure --enable-remote-bitbang --prefix=/home/$USER/tools/openocd
make
make install
export PATH=/home/$USER/tools/openocd/bin:$PATH
```

## Simulating

You need three shells, all opened in the root of the repository.

### 1. Start the simulation

Compile your application and the Verilator model as usual, then run the simulation in JTAG boot mode:

```bash
make app PROJECT=hello_world
make verilator-build
make verilator-run BOOTMODE=jtag
```

In this mode the testbench preloads the program, but it does not release the boot ROM: the CPU waits for the debugger. The simulation runs without cycle limit until the program exits. Use `make verilator-opt BOOTMODE=jtag` to avoid dumping waveforms, which makes debugging much faster.

The remote bitbang server prints:

```
Listening on port 4567
```

### 2. Connect OpenOCD

In a second shell, connect OpenOCD to the remote bitbang server:

```bash
export JTAG_VPI_PORT=4567
openocd -f tb/core-v-mini-mcu.cfg
```

OpenOCD initializes the debug module, halts the CPU and prints `Ready for Remote Connections.` It listens for GDB on port `3333`, and shuts down when GDB detaches.

### 3. Connect GDB

In a third shell, start GDB with the ELF of your application:

```bash
$RISCV_XALP/bin/riscv32-corev-elf-gdb sw/build/main.elf
```

and run:

```
(gdb) set remotetimeout 2000
(gdb) target extended-remote :3333
(gdb) load
(gdb) continue
```

`load` writes the program through the debug module and sets the program counter to its entry point. Keep in mind that this takes a long time, because the whole JTAG transfer is simulated.

The same commands are in `sw/gdbInit`, so you can also run:

```bash
make -C sw gdb_connect COMPILER_PREFIX=riscv32-corev-
```

The `.gdbinit` file in the root of the repository limits the GDB memory-write packet size, which makes `load` more robust. GDB only reads it if it is allowed by your `auto-load safe-path` setting.

From GDB you can then use the usual commands, for example:

```
(gdb) info reg pc
(gdb) disassemble
(gdb) break main
(gdb) stepi
```

When the program returns from `main()`, the simulation ends and the exit code is printed in the first shell.
