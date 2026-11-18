# x-alp
eXtendable Application Level Platform based on RISC-V

## Documentation

The documentation is in [`docs/source`](docs/source/index.rst) and is built with Sphinx (`make -C docs html`, output in `docs/build/html`).

## Getting Started

**New to X-ALP?** Check out the [Setup Guide](docs/source/GettingStarted/Setup.md) to get your development environment up and running, then follow the rest of the [Getting Started](docs/source/GettingStarted/index.rst) section:

- [Setup](docs/source/GettingStarted/Setup.md): prerequisites and tool installation
- [Generating the platform](docs/source/GettingStarted/GeneratingMCU.md): `make mcu-gen`
- [Compiling and running software](docs/source/GettingStarted/CompilingRunningSW.md): build `hello_world` and simulate it with Verilator
- [Understanding the tools](docs/source/GettingStarted/UnderstandingTools.md): vendor, FuseSoC and the Makefile targets
