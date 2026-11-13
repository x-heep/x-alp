# Simulate

X-ALP is simulated with [Verilator](https://www.veripool.org/verilator/). The simulation is driven by [FuseSoC](https://github.com/olofk/fusesoc) through the `sim` target of `xalp.core`; the `fusesoc` commands are wrapped by the targets of the top-level Makefile.

## Simulating with Verilator

First, build the Verilator model:

```bash
make verilator-build
```

This regenerates the platform files if a configuration or template changed, then compiles the RTL. The build log is written to `buildsim.log`, and the model to `build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/`.

Then, run the compiled application:

```bash
make verilator-run
```

`verilator-run` dumps the waveforms. To run faster, without waveforms, use:

```bash
make verilator-opt
```

At the end of the simulation, the Makefile prints the UART output, saved in `build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/uart0.log`. The testbench also prints the value returned by `main()` (`Exit code: <value>`).

You can view the waveform of the last simulation with GTKWave:

```bash
make verilator-waves
```

It opens `build/x-heep_x-alp_x-alp_0.0.1/sim-verilator/waveform.fst` with the signal list saved in `util/wave.gtkw`.

## Simulation parameters

The following parameters can be passed to `make verilator-run` and `make verilator-opt`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `BINARY` | `sw/build/main.spm.elf` | ELF file to load. The suffix before `.elf` (`spm` or `dram`) selects the memory to preload |
| `BOOTMODE` | `force` | `force`: preload the program and boot it. `jtag`: preload the program and wait for a debugger (see [Debug](./Debug.md)) |
| `MAX_CYCLES` | `1000000` | Maximum number of simulated clock cycles. Ignored with `BOOTMODE=jtag`, which runs until the program exits |
| `LOG_LEVEL` | `LOG_DEBUG` | Testbench verbosity: `LOG_NONE`, `LOG_LOW`, `LOG_MEDIUM`, `LOG_HIGH`, `LOG_FULL` or `LOG_DEBUG` |
| `FUSESOC_ARGS` | | Extra arguments for FuseSoC |

For example:

```bash
make verilator-run BINARY=$(pwd)/sw/build/main.dram.elf MAX_CYCLES=5000000 LOG_LEVEL=LOG_LOW
```

```{note}
`BINARY` should be an absolute path: FuseSoC runs the simulation from the build folder.
```

## How a program is loaded

With `BOOTMODE=force`, the Verilator testbench (`tb/src/verilator/tb_sim_ctrl.cpp`):

1. reads the ELF file and writes each section into the LLC scratchpad or into the DRAM model, depending on the `BINARY` suffix;
2. writes the ELF entry point into the `BOOT_ADDRESS` register of the SoC controller and releases the boot ROM wait loop;
3. runs until the SoC controller raises `exit_valid`, or until `MAX_CYCLES` is reached.

The CPU starts from the boot ROM (`hw/ip/bootrom/bootrom.S`). The boot ROM waits for the testbench, and, if the boot address is in the scratchpad, waits for the LLC built-in self-test and locks every cache way as scratchpad. Then it jumps to the program. When `main()` returns, the return value is written to the `EXIT_VALUE` register and `EXIT_VALID` is set, which ends the simulation.

```{note}
In simulation, the DRAM behind the LLC is modeled by a 64 KiB memory in `tb/src/testharness.sv`, so programs linked into `dram` must fit in 64 KiB.
```

## Simulating the UART DPI

To simulate the UART, X-ALP uses the lowRISC OpenTitan [UART DPI](https://github.com/lowRISC/opentitan/tree/master/hw/dv/dpi/uartdpi). Its output is written to `uart0.log` in the simulation folder, which is printed on the console when the simulation completes.
