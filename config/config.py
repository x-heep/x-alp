# Copyright X-HEEP contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Description: Default configuration for X-ALP

from XheepGen.xalp import XAlp
from XheepGen.cpu.cva6 import cva6
from XheepGen.bus import Bus, BusType
from XheepGen.peripherals.base_peripherals import (
    SOC_ctrl,
    Bootrom,
    Fast_intr_ctrl,
    Ext_peripheral,
)
from XheepGen.peripherals.user_peripherals import UART
from XheepGen.peripherals.generic_peripheral_domain import GenericPeripheralDomain


def config():
    system = XAlp()

    system.set_cpu(cva6())

    bus = Bus(BusType.onetoM)

    bus.add_master("CPU")
    bus.add_master("DEBUG_MODULE")
    bus.add_master("EXT_MASTER")

    bus.add_slave("MEM", 0x00000000, 0x10000)
    bus.add_slave("DEBUG_MODULE", 0x00010000, 0x10000)
    bus.add_slave("PERIPHERALS", 0x00020000, 0x10000000)
    bus.add_slave("EXT_SLAVE", 0x10020000, 0x10000)

    system.set_bus(bus)

    peripheral_domain = GenericPeripheralDomain(
        name="Peripherals",
        start_address=0x00020000,
        length=0x10000000,
    )
    peripheral_domain.add_peripheral(SOC_ctrl(0x0, 0x1000))
    peripheral_domain.add_peripheral(Bootrom(0x10000, 0x10000))
    peripheral_domain.add_peripheral(Fast_intr_ctrl(0x20000, 0x1000))
    peripheral_domain.add_peripheral(UART(0x30000, 0x1000))
    peripheral_domain.add_peripheral(Ext_peripheral(0x40000, 0x1000))

    system.add_peripheral_domain(peripheral_domain)

    return system
