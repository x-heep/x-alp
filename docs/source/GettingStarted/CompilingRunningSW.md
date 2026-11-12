# Compiling and running software

This page shows how to compile the `hello_world` application and run it on X-ALP with Verilator.

## Compiling applications

To compile the `hello_world` application, run:

```bash
make app
```

```{warning}
Don't forget to set the `RISCV_XALP` environment variable to the toolchain folder (without the `/bin` included), and to run `make mcu-gen` first.
```

The ELF files are written to `sw/build/`: `main.elf` and a copy named after the memory the program is linked into (`main.spm.elf` by default). You can find all the parameters for compiling applications in the [compiling applications guide](/How_to/CompileApps.md).

## Running applications

Build the Verilator model of X-ALP (this takes several minutes the first time):

```bash
make verilator-build
```

Then run the compiled application:

```bash
make verilator-run
```

When the simulation finishes, the UART output is printed on the console:

```
hello world!
```

The testbench also reports the value returned by `main()`, for example `Exit code: 0`. All the details about simulation are in the [simulating guide](/How_to/Simulate.md).

## Complete check

The following sequence checks the whole flow from a fresh clone:

```bash
conda activate core-v-mini-mcu
make mcu-gen
make app PROJECT=hello_world
make verilator-build
make verilator-run
```

You are now ready to follow the rest of the "How to..." guides.
