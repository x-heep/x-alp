# System Configuration

X-ALP is configured with two Python files:

- the **system configuration** (`X_ALP_CFG`, default `configs/soc.py`), which describes the CPU, the memory subsystem, the address map, the debug subsystem and the peripherals;
- the **pad configuration** (`PADS_CFG`, default `configs/pad_cfg.py`), which describes the pins and pads of the chip (see [Pad Configuration](./PadConfiguration.md)).

To run `mcu-gen` with your own configuration files, use:

```bash
make mcu-gen X_ALP_CFG=configs/my_soc.py PADS_CFG=configs/my_pad_cfg.py
```

```{note}
Unlike X-HEEP, X-ALP cannot be configured with make arguments (`CPU`, `BUS`, `MEMORY_BANKS`...) or with HJSON files: the generator only accepts a Python configuration file.
```

## Python configuration

The system configuration file must define a `config()` function that takes no parameters and returns an {py:class}`~xheep_gen.xalp.XAlp` instance. The configuration is address-map centric: the file declares the address map regions and connects the components to the system; the AXI bus is then derived automatically (see [Bus Configuration](./BusConfiguration.md)).

The default configuration, `configs/soc.py`, is the following:

```python
from xalp import XAlp
from cpu.cva6 import cva6
from address_map.address_map import AddressMap
from address_map.address_region import AddressRegion
from peripherals.peripheral_domain import PeripheralDomain
from peripherals.base_peripherals import SOC_ctrl, Bootrom, Fast_intr_ctrl, Ext_peripheral, LLC
from peripherals.user_peripherals import UART
from debug_ss.debug_ss import DebugSS


def config():
    soc = XAlp("X-ALP")

    # CPU
    soc.set_cpu(cva6())

    # Memory subsystem: the last-level cache
    llc = LLC(
        set_assoc=16,
        num_lines=256,
        num_blocks=8,
        spm_start=0x10000000,
        cached_start=0x80000000,
        cached_size=0x10000000,
    )
    soc.set_memory_ss(llc)

    # Address map
    peripheral_domain = AddressRegion("peripheral_domain", start_address=0x20000000, length=0x00100000)
    address_map = AddressMap()
    address_map.add_region(AddressRegion("debug", start_address=0x00000000, length=0x00100000))
    address_map.add_region(peripheral_domain)
    address_map.add_region(AddressRegion("ext_slaves", start_address=0xF0000000, length=0x01000000))
    soc.set_address_map(address_map)

    # Debug subsystem
    soc.set_debug_ss(DebugSS())

    # Peripherals
    peripherals = PeripheralDomain(
        peripheral_domain.get_name(),
        power_domain=None,
        clock_gating=False,
        peripherals=[SOC_ctrl(), Bootrom(), Ext_peripheral(), Fast_intr_ctrl(), UART(), llc],
    )
    soc.add_domain(peripherals)

    return soc
```

The configuration file is executed with `util/xheep_gen` on the Python path, so the modules of the generator can be imported directly.

## Generation steps

`util/xheep_gen/mcu_gen.py --system xalp` then:

1. loads the system configuration and the pad configuration;
2. calls {py:meth}`~xheep_gen.xalp.XAlp.build`, which places the peripherals, builds the memory subsystem and derives the AXI bus;
3. calls {py:meth}`~xheep_gen.system.System.validate`, which checks the configuration (see below);
4. renders all the templates. The system object is available in the templates both as `xalp` and as `xheep`, so templates shared with X-HEEP render unchanged.

## Validation rules

The generator stops with an error if:

- no CPU is set, or the CPU is not `cva6` ({py:attr}`~xheep_gen.xalp.XAlp.AVAILABLE_CPUS`), or more than one CPU is set;
- a peripheral is not in {py:attr}`~xheep_gen.xalp.XAlp.AVAILABLE_PERIPHERALS`, or one of the mandatory peripherals ({py:attr}`~xheep_gen.xalp.XAlp.MINIMUM_PERIPHERALS`: `soc_ctrl` and `bootrom`) is missing;
- the LLC geometry is not a power of two, or its regions overlap;
- a peripheral domain has no address map region with the same name, overlaps another domain, or starts below `0x10000`;
- the peripherals of a domain overlap or do not fit in it;
- no pad ring is configured.
