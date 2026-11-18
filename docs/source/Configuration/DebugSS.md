# Debug Subsystem Configuration

The debug subsystem provides run-control debugging over JTAG through the [RISC-V debug module](https://github.com/pulp-platform/riscv-dbg). It is represented by the {py:class}`~xheep_gen.debug_ss.debug_ss.DebugSS` class and set in the Python configuration with:

```python
from debug_ss.debug_ss import DebugSS

soc.set_debug_ss(DebugSS())
```

When a debug subsystem is set:

- the debug module becomes a master of the bus (`debug_module`), which gives the debugger system bus access;
- the debug module registers and ROM are reached through the `debug` slave, which must be a region of the [address map](./AddressMap.md). In the default configuration, it is at `0x0000_0000` with a length of 1 MiB. The CVA6 debug module base address is taken from this region.

The JTAG pins (`jtag_tck`, `jtag_tms`, `jtag_trst`, `jtag_tdi`, `jtag_tdo`) are defined in the [pad configuration](./PadConfiguration.md). See [Debug](../How_to/Debug.md) to debug a program in simulation.

## Parameters

{py:class}`~xheep_gen.debug_ss.debug_ss.DebugSS` exposes the `has_spi_slave` parameter (also settable with {py:meth}`~xheep_gen.debug_ss.debug_ss.DebugSS.set_spi_slave`), shared with X-HEEP. X-ALP does not implement the SPI slave debug interface, so keep the default value `0`.
