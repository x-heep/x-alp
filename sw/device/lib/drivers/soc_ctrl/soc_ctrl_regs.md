## Summary

| Name                                                   | Offset   |   Length | Description                                                                                                                     |
|:-------------------------------------------------------|:---------|---------:|:--------------------------------------------------------------------------------------------------------------------------------|
| soc_ctrl.[`EXIT_VALID`](#exit_valid)                   | 0x0      |        4 | Exit Valid - Used to write exit valid bit                                                                                       |
| soc_ctrl.[`EXIT_VALUE`](#exit_value)                   | 0x4      |        4 | Exit Value - Used to write exit value register                                                                                  |
| soc_ctrl.[`BOOT_SELECT`](#boot_select)                 | 0x8      |        4 | Boot Select Value - Used to decide boot mode                                                                                    |
| soc_ctrl.[`BOOT_EXIT_LOOP`](#boot_exit_loop)           | 0xc      |        4 | Boot Exit Loop Value - Set externally (e.g. JTAG, TESTBENCH, or another MASTER) to make the CPU jump to the main function entry |
| soc_ctrl.[`BOOT_ADDRESS`](#boot_address)               | 0x10     |        4 | Boot Address Value - Used in the boot rom or power-on-reset functions                                                           |
| soc_ctrl.[`SYSTEM_FREQUENCY_HZ`](#system_frequency_hz) | 0x14     |        4 | System Frequency Value - Used to know and set at which frequency the system is running (in Hz)                                  |

## EXIT_VALID
Exit Valid - Used to write exit valid bit
- Offset: `0x0`
- Reset default: `0x0`
- Reset mask: `0x1`

### Fields

```wavejson
{"reg": [{"name": "EXIT_VALID", "bits": 1, "attr": ["rw"], "rotate": -90}, {"bits": 31}], "config": {"lanes": 1, "fontsize": 10, "vspace": 120}}
```

|  Bits  |  Type  |  Reset  | Name       | Description    |
|:------:|:------:|:-------:|:-----------|:---------------|
|  31:1  |        |         |            | Reserved       |
|   0    |   rw   |    x    | EXIT_VALID | Exit Valid Reg |

## EXIT_VALUE
Exit Value - Used to write exit value register
- Offset: `0x4`
- Reset default: `0x0`
- Reset mask: `0xffffffff`

### Fields

```wavejson
{"reg": [{"name": "EXIT_VALUE", "bits": 32, "attr": ["rw"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
```

|  Bits  |  Type  |  Reset  | Name       | Description    |
|:------:|:------:|:-------:|:-----------|:---------------|
|  31:0  |   rw   |    x    | EXIT_VALUE | Exit Value Reg |

## BOOT_SELECT
Boot Select Value - Used to decide boot mode
- Offset: `0x8`
- Reset default: `0x0`
- Reset mask: `0x3`

### Fields

```wavejson
{"reg": [{"name": "BOOT_SELECT", "bits": 2, "attr": ["ro"], "rotate": -90}, {"bits": 30}], "config": {"lanes": 1, "fontsize": 10, "vspace": 130}}
```

|  Bits  |  Type  |  Reset  | Name                                     |
|:------:|:------:|:-------:|:-----------------------------------------|
|  31:2  |        |         | Reserved                                 |
|  1:0   |   ro   |    x    | [BOOT_SELECT](#boot_select--boot_select) |

### BOOT_SELECT . BOOT_SELECT
Boot Select Reg

| Value   | Name                | Description                                   |
|:--------|:--------------------|:----------------------------------------------|
| 0x0     | BOOT_SELECT_PASSIVE | Passive Boot (wait for JTAG or UART commands) |

Other values are reserved.

## BOOT_EXIT_LOOP
Boot Exit Loop Value - Set externally (e.g. JTAG, TESTBENCH, or another MASTER) to make the CPU jump to the main function entry
- Offset: `0xc`
- Reset default: `0x0`
- Reset mask: `0x1`

### Fields

```wavejson
{"reg": [{"name": "BOOT_EXIT_LOOP", "bits": 1, "attr": ["rw"], "rotate": -90}, {"bits": 31}], "config": {"lanes": 1, "fontsize": 10, "vspace": 160}}
```

|  Bits  |  Type  |  Reset  | Name           | Description   |
|:------:|:------:|:-------:|:---------------|:--------------|
|  31:1  |        |         |                | Reserved      |
|   0    |   rw   |    x    | BOOT_EXIT_LOOP | Boot Exit Reg |

## BOOT_ADDRESS
Boot Address Value - Used in the boot rom or power-on-reset functions
- Offset: `0x10`
- Reset default: `0x300`
- Reset mask: `0xffffffff`

### Fields

```wavejson
{"reg": [{"name": "BOOT_ADDRESS", "bits": 32, "attr": ["rw"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
```

|  Bits  |  Type  |  Reset  | Name         | Description      |
|:------:|:------:|:-------:|:-------------|:-----------------|
|  31:0  |   rw   |  0x300  | BOOT_ADDRESS | Boot Address Reg |

## SYSTEM_FREQUENCY_HZ
System Frequency Value - Used to know and set at which frequency the system is running (in Hz)
- Offset: `0x14`
- Reset default: `0x1`
- Reset mask: `0xffffffff`

### Fields

```wavejson
{"reg": [{"name": "SYSTEM_FREQUENCY_HZ", "bits": 32, "attr": ["rw"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
```

|  Bits  |  Type  |  Reset  | Name                | Description                                                     |
|:------:|:------:|:-------:|:--------------------|:----------------------------------------------------------------|
|  31:0  |   rw   |   0x1   | SYSTEM_FREQUENCY_HZ | Contains the value in Hz of the frequency the system is running |

