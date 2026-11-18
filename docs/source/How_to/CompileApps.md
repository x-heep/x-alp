# Compile applications

All software applications can be found in `sw/applications`. Each application is a folder with a single `main.c` file and, optionally, other source and header files. Applications are compiled with the `app` target of the top-level Makefile. To compile the `hello_world` application with default parameters, run:

```bash
make app
```

X-ALP uses CMake to compile and link, so the generated files are under `sw/build`. After a successful build, the memory usage of the program is printed.

```{warning}
Don't forget to set the `RISCV_XALP` env variable to the compiler folder (without the `/bin` included), and to run `make mcu-gen` before the first compilation.
```

## Parameters

You can select the application, the memory layout, the compiler, etc. with the following parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `PROJECT` | `hello_world` | Folder name of the application in `sw/applications` |
| `TARGET` | `sim` | Target platform; selects `sw/device/target/<TARGET>/`. Only `sim` is available |
| `LINKER` | `spm` | Memory layout: `spm`, `dram` or `rom` (see [below](#memory-layouts)) |
| `COMPILER` | `gcc` | `gcc` or `clang` |
| `COMPILER_PREFIX` | `riscv32-corev-` | Toolchain prefix, e.g. `riscv32-corev-` or `riscv32-unknown-` |
| `ARCH` | `rv64gc_zifencei` | ISA string passed to `-march` |
| `COMPILER_FLAGS` | `-mabi=lp64d` | Additional flags (ABI, optimization, preprocessor definitions) |
| `SOURCE` | `sw` of X-ALP | Software folder of an external project (see [eXtending software](../Extending/eXtendingSW.md)) |

```{note}
`COMPILER_FLAGS` replaces its default value, so keep `-mabi=lp64d` when you add flags, e.g. `make app COMPILER_FLAGS="-mabi=lp64d -DENABLE_DEBUG"`.
```

Run `make help` to see the most up-to-date documentation of the Makefile. To list the available applications, run `make app-list`.

## Memory layouts

The `LINKER` parameter selects one of the linker scripts in `sw/linker`. They all include `common.ldh`, which `make mcu-gen` generates from the platform configuration (see [Linker Configuration](../Configuration/LinkerConfiguration.md)).

| `LINKER` | Linker script | Code and data | Stack |
|----------|---------------|---------------|-------|
| `spm` | `spm.ld` | LLC scratchpad (`0x1000_0000`) | top of the scratchpad |
| `dram` | `dram.ld` | cached DRAM region (`0x8000_0000`) | top of the DRAM region |
| `rom` | `rom.ld` | runs from the scratchpad, load address in `extrom` (`0x0000_0000`); for images copied into the scratchpad by a loader | top of the scratchpad |

The build copies `main.elf` to `main.<LINKER>.elf`. The Verilator testbench reads this suffix to decide which memory to preload, so it can only load `spm` and `dram` images.

For example, to compile `hello_world` to run from DRAM:

```bash
make app PROJECT=hello_world LINKER=dram
make verilator-run BINARY=$(pwd)/sw/build/main.dram.elf
```

## Using other compilers

To use a standard RISC-V GCC or Clang toolchain, point `RISCV_XALP` to it and set the prefix:

```bash
make app COMPILER=gcc COMPILER_PREFIX=riscv32-unknown-

make app COMPILER=clang COMPILER_PREFIX=riscv32-unknown-
```

The toolchain must support the 64-bit `rv64gc` ISA and the `lp64d` ABI. With Clang, the LLD linker is used by default; pass `CLANG_LINKER_USE_LD=1` to link with the GCC linker instead.

## Compiling FreeRTOS based applications

The build system includes FreeRTOS when the name of the application contains `freertos`. X-ALP does not ship FreeRTOS applications yet.
