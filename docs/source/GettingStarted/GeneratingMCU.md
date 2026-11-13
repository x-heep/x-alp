# Generating the platform

X-ALP uses the `xheep_gen` Python package (vendored in `util/xheep_gen`) to model the platform and to generate the RTL, software headers and linker scripts from [Mako](https://www.makotemplates.org/) `.tpl` templates. For example, `hw/x_alp.sv.tpl` generates `hw/x_alp.sv` and `sw/device/lib/runtime/core_v_mcu.h.tpl` generates `sw/device/lib/runtime/core_v_mcu.h`.

To generate the default configuration of X-ALP, run from the repository root:

```bash
make mcu-gen
```

This command:

1. renders every `.tpl` file of the repository (outside `hw/vendor`, `util` and `test`) with the platform described in `configs/soc.py` and the pads described in `configs/pad_cfg.py`;
2. generates the register files of the peripherals (`make reg-gen`, see [Generating peripheral registers](../How_to/GenerateRegisters.md));
3. rebuilds the boot ROM (`make boot-rom`);
4. formats the generated code (`make format`).

```{warning}
Run `make mcu-gen` after cloning the repository and every time you change a configuration file or a `.tpl` template. Never edit a generated file directly: edit its `.tpl` template and run `make mcu-gen` again.
```

To generate a different platform, pass your own configuration files:

```bash
make mcu-gen X_ALP_CFG=configs/my_soc.py PADS_CFG=configs/my_pad_cfg.py
```

Unlike X-HEEP, X-ALP is configured only through Python files: there are no `CPU`, `BUS` or `MEMORY_BANKS` make arguments. You can find the full documentation in the [Configuration](/Configuration/index) section.

The generated address map is also written to `docs/addressmap.md` and shown in [Address Map](../Configuration/AddressMap.md).
