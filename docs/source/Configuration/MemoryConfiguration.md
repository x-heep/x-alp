# Memory Configuration

X-ALP has no on-chip RAM banks: its memory subsystem is the PULP [AXI last-level cache (LLC)](https://github.com/pulp-platform/axi_llc), represented by the {py:class}`~xheep_gen.peripherals.base_peripherals.llc.LLC` class.

The LLC is two things at once:

- a **memory subsystem**: it answers two address regions on a single crossbar port, its scratchpad (SPM) and the cached region it backs with the DRAM connected to its master port. Connect it with {py:meth}`~xheep_gen.system.System.set_memory_ss`.
- a **peripheral**: its configuration registers are a register-interface node in a peripheral domain. Add the same object to the peripheral domain to expose them.

## Default configuration

```python
from peripherals.base_peripherals import LLC

llc = LLC(
    set_assoc=16,
    num_lines=256,
    num_blocks=8,
    spm_start=0x10000000,
    cached_start=0x80000000,
    cached_size=0x10000000,
)
soc.set_memory_ss(llc)
...
# The same object is also added to the peripheral domain
peripherals = PeripheralDomain("peripheral_domain", peripherals=[..., llc])
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `set_assoc` | `16` | Number of ways. Must be a power of two |
| `num_lines` | `256` | Number of lines per way. Must be a power of two |
| `num_blocks` | `8` | Number of blocks per line. Must be a power of two |
| `data_width` | `64` | Block width in bits (AXI data width) |
| `spm_start` | `0x10000000` | Base address of the scratchpad region |
| `cached_start` | `0x80000000` | Base address of the cached (DRAM) region |
| `cached_size` | `0x10000000` | Size of the cached region in bytes |
| `offset` | `None` | Offset of the configuration registers in their peripheral domain (`None`: placed automatically) |
| `length` | `0x10000` | Size of the configuration register region |

The geometry parameters (`set_assoc`, `num_lines`, `num_blocks`, `data_width`) drive the `axi_llc` instance in the RTL. They also fix the size of the scratchpad, which is the whole cache capacity:

```
SPM size = set_assoc * num_lines * num_blocks * data_width / 8
```

With the default values, the scratchpad is 16 × 256 × 8 × 64 / 8 = 256 KiB.

## Scratchpad and cache ways

Each way of the LLC can be used either as cache or as scratchpad. Out of reset, every way is configured as cache, and an access to the scratchpad region of a way still used as cache returns an error. When the boot address is in the scratchpad, the boot ROM waits for the LLC built-in self-test and then locks every way as scratchpad before jumping to the program. A program that runs from DRAM keeps every way as cache, and can switch ways to scratchpad through the LLC configuration registers (see [Peripherals](../Peripherals/index.md)).

## Linker sections

The memory subsystem regions are described as linker sections. Unless the configuration adds its own sections, the LLC declares two of them when the system is built:

| Section | Start | Size |
|---------|-------|------|
| `llc` | `spm_start` | SPM size |
| `dram` | `cached_start` | `cached_size` |

These sections:

- become the two regions answered by the LLC slave port of the bus (see [Bus Configuration](./BusConfiguration.md));
- are marked executable and cacheable for the CPU (see [CPU Configuration](./CPUConfiguration.md));
- define the `spm` and `dram` memories of the linker scripts (see [Linker Configuration](./LinkerConfiguration.md)).

The generator checks that the regions do not overlap.

## DRAM

The DRAM itself is outside X-ALP: it is connected to the LLC master port, `ext_llc_req_o`/`ext_llc_rsp_i`, of the `x_alp` top level. In simulation, the testbench (`tb/src/testharness.sv`) connects a 64 KiB memory model to this port.
