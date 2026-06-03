## Summary

| Name                                | Offset   |   Length | Description      |
|:------------------------------------|:---------|---------:|:-----------------|
| spi_subsystem.[`CONTROL`](#control) | 0x0      |        4 | Control register |

## CONTROL
Control register
- Offset: `0x0`
- Reset default: `0x0`
- Reset mask: `0x3`

### Fields

```wavejson
{"reg": [{"name": "USE_AXI", "bits": 1, "attr": ["rw"], "rotate": -90}, {"name": "A2F_CTR_POWERON_EN", "bits": 1, "attr": ["rw"], "rotate": -90}, {"bits": 30}], "config": {"lanes": 1, "fontsize": 10, "vspace": 200}}
```

|  Bits  |  Type  |  Reset  | Name               | Description                                                                     |
|:------:|:------:|:-------:|:-------------------|:--------------------------------------------------------------------------------|
|  31:2  |        |         |                    | Reserved                                                                        |
|   1    |   rw   |   0x0   | A2F_CTR_POWERON_EN | enables the power-on sfm in axi_to_flash_controller                             |
|   0    |   rw   |   0x0   | USE_AXI            | selects between the two flash controllers, as flash master and interrupt source |

