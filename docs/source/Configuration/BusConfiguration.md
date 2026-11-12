# Bus Configuration

X-ALP uses an AXI4 crossbar (the PULP `axi_xbar`) with 64-bit addresses and 64-bit data. Unlike X-HEEP, the bus is not configured directly: there is no `onetoM`/`NtoM` bus type. The {py:class}`~xheep_gen.bus.bus.Bus` object is derived from the configuration when {py:meth}`~xheep_gen.xalp.XAlp.build` is called, and is available in the templates with `xalp.bus()`.

## Masters

The masters follow the connected components, in this order:

1. `cpu`, when a CPU is set;
2. `debug_module`, when a debug subsystem is set (system bus access of the debugger);
3. one master per master port of every peripheral that masters the bus;
4. `ext_master`, which always exists and is tied off when unused (see [eXtending hardware](../Extending/eXtendingHW.md)).

## Slaves

The slaves are:

- the memory subsystem, when one is connected. The LLC answers its scratchpad and its cached region on the same port: the lowest region (`llc`) is the region of the slave and the other ones (`dram`) are added as extra address decoding rules to the same port;
- one slave per address map region, keeping the region name. A region with the same name as a peripheral domain becomes that domain: its peripherals become register-interface slaves behind an AXI-to-register-interface bridge (`axi_to_reg_v2`) and a register demultiplexer.

The slaves are ordered by address. Each slave gets an index, used in the generated `core_v_mcu_pkg` package (e.g. `EXT_SLAVES_S_BUS_IDX`, `UART_REG_IDX`).

## Default bus

| Masters | Slaves |
|---------|--------|
| `cpu`, `debug_module`, `ext_master` | `debug` (`0x0000_0000`), `llc` (`0x1000_0000`) and `dram` (`0x8000_0000`) on the same port, `peripheral_domain` (`0x2000_0000`), `ext_slaves` (`0xF000_0000`) |

The complete generated address map is in [Address Map](./AddressMap.md).
