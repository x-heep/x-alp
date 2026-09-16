# Copyright 2026 Politecnico di Torino
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author(s): David Mallasen
# Description: Generic (default) configuration for X-ALP

from xalp import XAlp
from cpu.cva6 import cva6
from address_map.address_map import AddressMap
from address_map.address_region import AddressRegion

from peripherals.peripheral_domain import PeripheralDomain
from peripherals.base_peripherals import (
    SOC_ctrl,
    Bootrom,
    Fast_intr_ctrl,
    Ext_peripheral,
)
from peripherals.user_peripherals import (
    UART,
)

from memory_ss.memory_ss import MemorySS
from memory_ss.linker_section import LinkerSection
from debug_ss.debug_ss import DebugSS
from memory_ss.memory_ss import MemorySS
from memory_ss.linker_section import LinkerSection


def config():

    soc = XAlp("X-ALP")

    soc.set_cpu(cva6())

    peripheral_domain = AddressRegion(
        "peripheral_domain", start_address=0x20000000, length=0x00100000
    )

    memory = MemorySS()
    memory.add_ram_banks([64] * 2)
    memory.add_linker_section(LinkerSection.by_size("code", 0, 0x00008000))
    memory.add_linker_section(LinkerSection("data", 0x00008000, None))
    soc.set_memory_ss(memory)

    address_map = AddressMap()
    address_map.add_region(
        AddressRegion("debug", start_address=0x10000000, length=0x00100000)
    )

    address_map.add_region(peripheral_domain)
    address_map.add_region(
        AddressRegion("ext_slaves", start_address=0xF0000000, length=0x01000000)
    )
    soc.set_address_map(address_map)

    soc.set_debug_ss(DebugSS())

    peripherals = PeripheralDomain(
        peripheral_domain.get_name(),
        power_domain=None,
        clock_gating=False,
        peripherals=[
            SOC_ctrl(),
            Bootrom(),
            Ext_peripheral(),
            Fast_intr_ctrl(),
            UART(),
        ],
    )
    soc.add_domain(peripherals)

    return soc
