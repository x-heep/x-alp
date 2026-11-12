# Peripheral Configuration

The default configuration of the peripherals can be found in `configs/soc.py`. A custom configuration can be created through the [Python configuration](./SystemConfiguration.md).

## Overall structure

Peripherals are grouped in peripheral domains, instances of {py:class}`~xheep_gen.peripherals.peripheral_domain.PeripheralDomain`. Each domain is an independent node of the bus: it is connected to the crossbar through one AXI port, bridged to the register interface and decoded a second time to reach each peripheral. Unlike X-HEEP, which has a fixed base and user domain, X-ALP accepts any number of domains with any name. The default configuration has a single domain, `peripheral_domain`.

Each domain:

- must have an [address map](./AddressMap.md) region with the same name, which gives it its start address and length;
- can be assigned to a power domain (`power_domain`, `None` means always-on) and can support clock gating (`clock_gating`). These properties are available to the templates through {py:meth}`~xheep_gen.xalp.XAlp.get_power_domains`, {py:meth}`~xheep_gen.xalp.XAlp.get_always_on_domains` and {py:meth}`~xheep_gen.xalp.XAlp.get_clock_gated_domains`. The current X-ALP RTL does not implement power or clock gating yet;
- is added to the system with `soc.add_domain()`.

Every peripheral is represented by a Python class, imported from `peripherals.base_peripherals` or `peripherals.user_peripherals`. Each peripheral has an offset and a length, relative to the start of its domain. Peripherals with registers have an HJSON description (see [Generate peripheral registers](../How_to/GenerateRegisters.md)).

## Available peripherals

X-ALP supports the peripherals listed in {py:attr}`~xheep_gen.xalp.XAlp.AVAILABLE_PERIPHERALS`. Using any other peripheral class raises an error.

| Name | Class | Mandatory | Description |
|------|-------|-----------|-------------|
| `soc_ctrl` | `SOC_ctrl` | yes | SoC controller: boot address, boot handshake and exit value |
| `bootrom` | `Bootrom` | yes | Boot ROM |
| `fast_intr_ctrl` | `Fast_intr_ctrl` | no | Fast interrupt controller |
| `uart` | `UART` | no | OpenTitan UART |
| `axi_llc` | `LLC` | no | Configuration registers of the last-level cache |
| `ext_peripheral` | `Ext_peripheral` | no | Register-interface port for a peripheral outside X-ALP |
| `pad_control` | `Pad_control` | no | Pad control registers |

The boot flow and the software runtime rely on `soc_ctrl`, `bootrom`, `uart` and, when booting from the scratchpad, `axi_llc`. See [Peripherals](../Peripherals/index.md) for a description of each one.

## Adding a custom configuration

```python
from peripherals.peripheral_domain import PeripheralDomain
from peripherals.base_peripherals import SOC_ctrl, Bootrom, Fast_intr_ctrl, Ext_peripheral
from peripherals.user_peripherals import UART

peripheral_domain = AddressRegion("peripheral_domain", start_address=0x20000000, length=0x00100000)
address_map.add_region(peripheral_domain)

peripherals = PeripheralDomain(
    peripheral_domain.get_name(),
    power_domain=None,
    clock_gating=False,
    peripherals=[
        SOC_ctrl(),
        Bootrom(),
        Ext_peripheral(),
        Fast_intr_ctrl(),
        UART(offset=0x40000),  # fixed offset
        llc,                   # the LLC object used as memory subsystem
    ],
)
soc.add_domain(peripherals)
```

Peripherals can also be added one by one with {py:meth}`~xheep_gen.peripherals.peripheral_domain.PeripheralDomain.add_peripheral`. Changes made to a peripheral after it has been added are not recorded.

When creating a peripheral, the offset, the length (64 KiB by default) and the other peripheral-specific parameters can be passed to the constructor. Peripherals with and without an explicit offset can coexist in the same domain. When {py:meth}`~xheep_gen.xalp.XAlp.build` is called, the missing offsets are computed with a greedy algorithm that places the peripherals in the free space of the domain, from the largest to the smallest. If there is not enough space, an error is raised. {py:meth}`~xheep_gen.system.System.validate` then checks that no peripheral overlaps another one or lies outside its domain.

In the templates, a peripheral can be found with {py:meth}`~xheep_gen.peripherals.peripheral_domain.PeripheralDomain.get_peripheral`, and its final address through the bus (`xalp.bus().get_reg_slaves()`). In software, the generated `core_v_mcu.h` header defines `<NAME>_BASE_ADDRESS` (and the `<NAME>_START_ADDRESS` alias) for every peripheral, e.g. `SOC_CTRL_BASE_ADDRESS`.
