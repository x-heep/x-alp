# X-HEEP System Generator

A Python framework for programmatically configuring and generating MCU/SoC system specifications for the X-HEEP (eXtensible Heterogeneous Energy-Efficient Processor) platform.

## Overview

`system_gen` provides a modular, configuration-as-code approach to defining:

- **CPU cores** — CV32E20, CV32E40P, CV32E40PX, CV32E40X variants
- **Memory subsystem** — RAM banks (continuous/interleaved), linker sections
- **Peripheral domains** — Base (mandatory) and user (optional) peripherals
- **Pad ring** — I/O pad configuration and layout
- **Bus architecture** — One-to-Many and N-to-Many topologies

## Project Structure

```
system_gen/
├── load_config.py          # Configuration loader (HJSON / Python configs)
├── system.py               # Core system abstraction (ABC)
├── bus_type.py              # Bus type enumeration
├── cpu/                     # CPU variant implementations
│   ├── cpu.py               #   Base CPU class
│   ├── cv32e20.py
│   ├── cv32e40p.py
│   ├── cv32e40px.py
│   └── cv32e40x.py
├── memory_ss/               # Memory subsystem
│   ├── memory_ss.py         #   Memory subsystem manager
│   ├── ram_bank.py          #   RAM bank abstraction
│   ├── il_ram_group.py      #   Interleaved RAM groups
│   └── linker_section.py    #   Linker section definitions
├── peripherals/             # Peripheral definitions
│   ├── abstractions.py      #   Abstract base classes
│   ├── base_peripherals/    #   Mandatory system peripherals
│   └── user_peripherals/    #   Optional/configurable peripherals
└── pads/                    # I/O pad configuration
    ├── Pad.py
    └── PadRing.py
```

## Usage

System configurations can be defined via HJSON files or Python modules:

```python
from system_gen.load_config import load_cfg_file

system = load_cfg_file("path/to/config.hjson")
```

Python-based configs export a `config()` function that returns a `System` instance.

## Dependencies

- Python 3.8+
- `hjson`
- `jsonref`