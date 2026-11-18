# CPU Configuration

X-ALP supports a single CPU: the OpenHW Group [CVA6](https://github.com/openhwgroup/cva6), a 64-bit, six-stage, in-order application-class RISC-V core. It is selected in the Python configuration with:

```python
from cpu.cva6 import cva6

soc.set_cpu(cva6())
```

The CPU is represented by the {py:class}`~xheep_gen.cpu.cva6.cva6` class. {py:attr}`~xheep_gen.xalp.XAlp.AVAILABLE_CPUS` only contains `cva6`, and {py:meth}`~xheep_gen.xalp.XAlp.set_cpu` raises an error if a second CPU is set.

## Core parameters

The parameters of the core are set in the CVA6 configuration package, generated from `hw/include/cva6_config_pkg.sv.tpl`. To change them, edit the template and run `make mcu-gen`. The default values are:

| Parameter | Value |
|-----------|-------|
| XLEN | 64 |
| ISA | RV64GC with B (bit manipulation), Zicond and Zcb; no H or V extensions |
| Floating point | single and double precision (F and D) |
| CV-X-IF | enabled in the core |
| MMU | present (Sv39) |
| PMP | 8 entries |
| Instruction cache | 16 KiB, 4-way, 128-bit lines |
| Data cache | 32 KiB, 8-way, 128-bit lines, write-through |
| AXI port | 64-bit address and data, ID width from `core_v_mcu_pkg` |
| Boot address | base of the boot ROM |

The default software flow matches this configuration: `ARCH=rv64gc_zifencei` and `COMPILER_FLAGS=-mabi=lp64d` (see [Compile applications](../How_to/CompileApps.md)).

## Executable and cacheable regions

CVA6 only fetches instructions from executable regions and only caches accesses to cacheable regions. These regions are derived from the configuration when the package is generated:

- **executable**: the debug region, the boot ROM and every linker section of the memory subsystem;
- **cacheable**: every linker section of the memory subsystem.

With the default [memory configuration](./MemoryConfiguration.md), the LLC scratchpad and the cached DRAM region are both executable and cacheable; the peripherals are neither.

## Debug

The CVA6 configuration package also sets the debug module base address, taken from the `debug` region of the address map (`DEBUG_BUS_BASE_ADDR`), and the debug halt and exception addresses (`0x800` and `0x808`). See [Debug Subsystem Configuration](./DebugSS.md).
