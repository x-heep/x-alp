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
    LLC,
)
from peripherals.user_peripherals import (
    UART,
)

from debug_ss.debug_ss import DebugSS


def config():

    soc = XAlp("X-ALP")

    soc.set_cpu(cva6())

    peripheral_domain = AddressRegion(
        "peripheral_domain", start_address=0x20000000, length=0x00100000
    )

    # The memory subsystem is the last-level cache: its scratchpad answers at
    # 0x10000000 and the region it caches, backed by the DRAM on its master
    # port, at 0x80000000. Both are cacheable and executable by default.
    llc = LLC(
        set_assoc=16,
        num_lines=256,
        num_blocks=8,
        spm_start=0x10000000,
        cached_start=0x80000000,
        cached_size=0x10000000,
    )
    soc.set_memory_ss(llc)

    address_map = AddressMap()
    # Kept at 0x00000000: the debug module ROM is where the linker places
    # `extrom`, which the boot ROM hands control to.
    address_map.add_region(
        AddressRegion("debug", start_address=0x00000000, length=0x00100000)
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
            llc,
        ],
    )
    soc.add_domain(peripherals)

    return soc
