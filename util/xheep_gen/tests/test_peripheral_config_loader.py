# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for peripherals.peripheral_config_loader: creating base/user
peripheral domains from an HJSON configuration."""

import hjson
import pytest

from bus_type import BusType
from peripherals.peripheral_config_loader import load_peripherals_config
from peripherals.user_peripherals_domain import UserPeripheralDomain
from xheep import XHeep


def parse(src):
    return hjson.loads(src, parse_int=int, object_pairs_hook=hjson.OrderedDict)


DMA_CFG = """
dma: {
    offset: 0x10000
    length: 0x10000
    addr_mode_en: yes
    subaddr_mode_en: no
    hw_fifo_mode_en: yes
    zero_padding_en: no
    ch_length: "0x100"
    num_channels: "0x2"
    num_master_ports: "0x2"
    num_channels_per_master_port: "0x1"
    fifo_depth: "0x8"
}
"""

FULL_CFG = f"""
{{
    ao_peripherals: {{
        address: "0x20000000"
        length: "0x00100000"
        soc_ctrl: {{
            offset: "0x0"
            length: "0x10000"
        }}
        bootrom: {{
            offset: "0x20000"
            length: "0x10000"
            is_included: no
        }}
        {DMA_CFG}
    }}
    peripherals: {{
        address: "0x30000000"
        length: "0x00100000"
        uart: {{
            offset: "0x0"
            length: "0x10000"
        }}
        gpio: {{
            offset: "0x10000"
            length: "0x10000"
            is_included: no
        }}
    }}
}}
"""


class TestLoadPeripheralsConfig:
    def test_domains_are_created(self):
        system = XHeep(BusType.onetoM)
        load_peripherals_config(system, parse(FULL_CFG))
        assert system.are_peripherals_configured()

        base = system.get_base_peripheral_domain()
        assert base.get_start_address() == 0x20000000
        assert base.contains_peripheral("soc_ctrl")

        user = system.get_user_peripheral_domain()
        assert user.get_start_address() == 0x30000000
        assert user.contains_peripheral("uart")

    def test_base_peripherals_ignore_is_included(self):
        # In the AO domain only the DMA honors is_included; other base
        # peripherals marked "no" are skipped.
        system = XHeep(BusType.onetoM)
        load_peripherals_config(system, parse(FULL_CFG))
        assert not system.get_base_peripheral_domain().contains_peripheral("bootrom")

    def test_user_peripheral_not_included_is_skipped(self):
        system = XHeep(BusType.onetoM)
        load_peripherals_config(system, parse(FULL_CFG))
        assert not system.get_user_peripheral_domain().contains_peripheral("gpio")

    def test_dma_configuration_is_applied(self):
        system = XHeep(BusType.onetoM)
        load_peripherals_config(system, parse(FULL_CFG))
        dma = system.get_base_peripheral_domain().get_dma()
        assert dma.get_address() == 0x10000
        assert dma.get_num_channels() == 2
        assert dma.get_num_master_ports() == 2
        assert dma.get_fifo_depth() == 8
        assert dma.get_addr_mode() == 1
        assert dma.get_subaddr_mode() == 0
        assert dma.get_hw_fifo_mode() == 1
        assert dma.get_zero_padding() == 0

    def test_dma_not_included_uses_defaults(self):
        cfg = parse(
            """
            {
                ao_peripherals: {
                    address: "0x20000000"
                    length: "0x00100000"
                    dma: {
                        offset: "0x10000"
                        length: "0x10000"
                        is_included: no
                    }
                }
            }
            """
        )
        system = XHeep(BusType.onetoM)
        load_peripherals_config(system, cfg)
        dma = system.get_base_peripheral_domain().get_dma()
        assert dma.get_is_included() == 0
        assert dma.get_num_channels() == 1
        assert dma.get_addr_mode() == 0

    def test_dma_invalid_mode_rejected(self):
        cfg = parse(FULL_CFG.replace("addr_mode_en: yes", "addr_mode_en: maybe"))
        system = XHeep(BusType.onetoM)
        with pytest.raises(ValueError, match="addr_mode_en"):
            load_peripherals_config(system, cfg)

    def test_unknown_peripheral_rejected(self):
        cfg = parse(
            """
            {
                peripherals: {
                    address: "0x30000000"
                    length: "0x00100000"
                    quantum_modem: {
                        offset: "0x0"
                        length: "0x10000"
                    }
                }
            }
            """
        )
        system = XHeep(BusType.onetoM)
        with pytest.raises(ValueError, match="quantum_modem"):
            load_peripherals_config(system, cfg)

    def test_already_configured_domain_is_not_overwritten(self):
        system = XHeep(BusType.onetoM)
        domain = UserPeripheralDomain()
        system.add_peripheral_domain(domain)
        load_peripherals_config(system, parse(FULL_CFG))
        # The hjson user domain (with uart) must not replace the python one.
        assert not system.get_user_peripheral_domain().contains_peripheral("uart")
