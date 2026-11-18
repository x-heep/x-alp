# eXtending hardware

To extend X-ALP with your own IPs, create a top-level repository that contains both X-ALP and your IPs, and instantiate the `x_alp` module in your own top level.

## Repository structure

The following is an example repository folder structure.

    BASE
    ├── hw
    │   ├── TOP
    │   │   └── top.sv
    │   └── vendor
    │       ├── your_accelerator
    │       ├── your_accelerator.vendor.hjson
    │       ├── x-heep_x-alp
    │       └── x-heep_x-alp.vendor.hjson
    ├── top.core
    ├── tb
    │   └── testharness.sv
    ├── util
    │   └── vendor.py
    ├── Makefile
    └── sw

## Vendoring X-ALP

We recommend using the [vendor](https://opentitan.org/book/util/doc/vendor.html) tool, as [used inside X-ALP](../GettingStarted/UnderstandingTools.md#vendor), although you could use git submodules instead. Create a `hw/vendor` directory in your top-level repository (`BASE`) containing a file named `x-heep_x-alp.vendor.hjson`:

<details>
    <summary>Example of x-heep_x-alp.vendor.hjson</summary>

```
{
  name: "x-heep_x-alp"
  target_dir: "x-heep_x-alp"

  upstream: {
    url: "https://github.com/x-heep/x-alp.git"
    rev: "main"
  }

  exclude_from_upstream: [
    ".github"
  ]
}
```
</details><br>

Replace `main` with a specific commit to prevent accidental updates to an incompatible revision. Then add the [vendor script](https://github.com/lowRISC/opentitan/blob/master/util/vendor.py) to `BASE/util` and run from `BASE`:

```bash
util/vendor.py --update hw/vendor/x-heep_x-alp.vendor.hjson
```

## Connecting your IPs

The `x_alp` module (`hw/x_alp.sv`, generated from `hw/x_alp.sv.tpl`) contains the pad ring and the `core_v_mcu`. Instantiate it in your top level and connect your IPs to its external interfaces. The interface types are defined in the generated `core_v_mcu_pkg` package (`hw/include/core_v_mcu_pkg.sv`):

| Port | Type | Direction | Use |
|------|------|-----------|-----|
| `ext_slv_req_o` / `ext_slv_rsp_i` | `axi_slv_req_t` / `axi_slv_rsp_t` | X-ALP is master | Accelerator or memory in the `ext_slaves` region |
| `ext_mst_req_i` / `ext_mst_rsp_o` | `axi_mst_req_t` / `axi_mst_rsp_t` | X-ALP is slave | External master accessing the X-ALP memory map |
| `ext_reg_req_o` / `ext_reg_rsp_i` | `reg_req_t` / `reg_rsp_t` | X-ALP is master | Registers of an external peripheral in the `ext_peripheral` slot |
| `ext_llc_req_o` / `ext_llc_rsp_i` | `axi_mst_req_t` / `axi_mst_rsp_t` | X-ALP is master | DRAM behind the last-level cache |

All AXI interfaces use 64-bit addresses and 64-bit data. Tie the unused inputs to `'0`.

X-ALP's testbench (`tb/src/testharness.sv`) is a complete example. It connects:

- a memory to `ext_slv`, through an `axi_to_mem` adapter. The `example_ext_slv` application writes and reads it back;
- a 64 KiB DRAM model to `ext_llc`;
- `'0` to the unused `ext_mst` and `ext_reg` inputs.

## Placing your IPs in the memory map

The external slave window and the external peripheral slot are part of the [Python configuration](../Configuration/SystemConfiguration.md):

- the `ext_slaves` region of the address map sets the base address and size of the AXI slave window. Your IPs must decode their own addresses inside it;
- the `Ext_peripheral()` entry of the peripheral domain sets the slot of the register-interface port (64 KiB by default; pass `offset` and `length` to change it).

Both are then visible to software through the generated `core_v_mcu.h` header (`EXT_SLAVES_START_ADDRESS`, `EXT_PERIPHERAL_START_ADDRESS`...). To generate the X-ALP files with your own configuration, run `mcu-gen` from the vendored X-ALP folder:

```bash
make -C hw/vendor/x-heep_x-alp mcu-gen X_ALP_CFG=$(pwd)/configs/my_soc.py PADS_CFG=$(pwd)/configs/my_pad_cfg.py
```

Your own templates can be rendered with the same configuration by passing them to `mcu-gen` with the `EXTERNAL_MCU_GEN_TEMPLATES` variable.
