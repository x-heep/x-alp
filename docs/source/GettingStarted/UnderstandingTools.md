# Understanding the tools

This section gives a brief overview of the main tools used in the development of X-ALP.

## Vendor

X-ALP uses the [vendor tool](https://opentitan.org/book/util/doc/vendor.html) from OpenTitan to manage the code included from external repositories. The vendor tool copies upstream sources into the repository. You can find it in `util/vendor.py`, and the vendored repositories in `hw/vendor` (hardware IPs such as CVA6, the AXI LLC and X-HEEP itself) and `util` (the `xheep_gen` generator).

Each vendored repository has a `<name>.vendor.hjson` description file, which tells the vendor tool where to fetch the upstream repository and which modifications to apply. The vendor tool can apply git patches to the vendored repository: to create one, clone the upstream repository, make your changes, stage them with `git add` and run `git diff main > my_patch.patch`.

To vendor or re-vendor a single repository, run from the root of the repository:

```bash
util/vendor.py --update hw/vendor/<name>.vendor.hjson
```

To update all of them and check the result:

```bash
make vendor-update
```

```{warning}
The CI re-vendors every repository and fails if the result differs from the committed files. Do not edit vendored files by hand: change them upstream or through a patch.
```

For more details, check the [official vendor documentation](https://opentitan.org/book/util/doc/vendor.html).

## FuseSoC and .core files

[FuseSoC](https://fusesoc.readthedocs.io/en/stable/index.html) is an open-source package manager and build system for hardware designs. It manages dependencies, configurations and tool flows. X-ALP uses the X-HEEP fork of FuseSoC, installed with the Python environment.

The main building blocks of FuseSoC are the `.core` files. A `.core` file is a self-contained description of a hardware module, including its sources, dependencies and configurations. The main `.core` file of X-ALP is `xalp.core` (core name `x-heep:x-alp:x-alp:0.0.1`), which defines the `sim`, `lint` and `format` targets and the simulation parameters. The other `.core` files are in `hw/` (e.g. `hw/core_v_mcu.core`) and `tb/` (`tb/tb.core`).

The top-level `Makefile` uses FuseSoC behind the scenes to build, simulate and lint the design. Build outputs are written to `build/x-heep_x-alp_x-alp_0.0.1/`. To write your own `.core` files, check the [FuseSoC documentation](https://fusesoc.readthedocs.io/en/stable/user/build_system/core_files.html).

## Make

All the flows are driven from the top-level `Makefile`. Run `make help` to see the available targets and their parameters:

| Target | Description |
|--------|-------------|
| `conda` | Create the `core-v-mini-mcu` conda environment |
| `mcu-gen` | Generate the platform from the configuration files |
| `reg-gen` | Generate the peripheral register files |
| `boot-rom` | Rebuild the boot ROM |
| `app` | Compile an application |
| `app-list` | List the available applications |
| `verilator-build` | Build the Verilator model |
| `verilator-run` | Run a simulation with waveforms |
| `verilator-opt` | Run a simulation without waveforms (faster) |
| `verilator-waves` | Open the last waveform with GTKWave |
| `format` | Format SystemVerilog and C/C++ files |
| `lint` | Lint the design with Verible |
| `vendor-update` | Update the vendored repositories |
| `clean-app` | Remove `sw/build` |
| `clean` | Remove build folders and generated files |
