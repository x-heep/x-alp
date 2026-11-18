# Testing applications

X-ALP uses the applications in `sw/applications` as functional tests. An application passes when it compiles and, in simulation, returns `0` from `main()` (`EXIT_SUCCESS`).

## The test_apps script

`test/test_apps/test_apps.py` compiles every application with each compiler and memory layout, and then simulates it with Verilator. Run it from the root of the repository, after `make mcu-gen`:

```bash
export RISCV_XALP=/path/to/your/toolchain
python3 test/test_apps/test_apps.py --compilers gcc --compiler-prefixes riscv32-corev- --linkers spm --table
```

| Option | Description |
|--------|-------------|
| `--compile-only` | Only compile the applications |
| `--compilers` | Comma-separated list of compilers to test (default: `gcc,clang`) |
| `--compiler-prefixes` | One prefix for all compilers, or one per compiler |
| `--compiler-paths` | One toolchain path for all compilers, or one per compiler |
| `--linkers` | Comma-separated list of memory layouts to compile (default: `spm,dram`) |
| `--table` | Print the results in a table |
| `--dry-run` | Print the commands without running them |

```{note}
The compilation flow reads the toolchain path from `RISCV_XALP`, so set it in your environment before running the script.
```

The script:

1. builds the Verilator model once (`make verilator-build`), unless `--compile-only` is set;
2. compiles each application with every compiler and memory layout (`make app PROJECT=<app> COMPILER=... COMPILER_PREFIX=... LINKER=...`). The combinations are compiled in reverse order, so the build left in `sw/build` is the one of the first compiler and the first memory layout;
3. simulates that build (`make verilator-run`). A simulation passes when the testbench prints `Exit code: 0`, and times out after 180 seconds.

The script exits with an error if any application fails to compile or to run. To restrict or skip applications, edit the `WHITELIST`, `BLACKLIST`, `CLANG_BLACKLIST` and `VERILATOR_BLACKLIST` lists at the top of the script.

## Continuous integration

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every pull request, inside the X-HEEP toolchain Docker image, with `ARCH=rv64gc_zifencei` and `COMPILER_PREFIX=riscv32-corev-`. It contains the following jobs:

| Job | Description |
|-----|-------------|
| Vendor up-to-date | Re-vendors every repository and fails if the result differs from the committed files |
| Lint Generated Files | Runs `make mcu-gen` and fails if the generated files differ from the committed ones |
| Compile All Apps | Compiles every application with GCC (`test_apps.py --compile-only`) |
| Simulate All Apps | Compiles and simulates every application with the `spm` layout |

```{note}
Before opening a pull request, run `make mcu-gen` and commit the generated files that are tracked by git, otherwise the "Lint Generated Files" job fails.
```
