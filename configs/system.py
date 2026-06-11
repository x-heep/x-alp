# Copyright 2026 Politecnico di Torino
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author(s): David Mallasen
# Description: Generic (default) configuration for X-ALP

from xalp import XAlp
from bus import Bus, AxiMaster, BusSlave
from cpu.cva6 import cva6
from bus_type import BusType

from peripherals.base_peripherals import (
    SOC_ctrl,
    Bootrom,
    Fast_intr_ctrl,
    Ext_peripheral,
)

from peripherals.user_peripherals import (
    UART,
)

from peripherals.peripheral_subsystem import PeripheralSubsystem

from memory_ss.memory_ss import MemorySS
from memory_ss.linker_section import LinkerSection


def config():

    bus = Bus(BusType.onetoM)

    # ------------------------------------------------------------
    # AXI masters
    # ------------------------------------------------------------
    bus.add_master(AxiMaster("cpu"))
    bus.add_master(AxiMaster("debug_module"))
    bus.add_master(AxiMaster("ext_master"))

    # ------------------------------------------------------------
    # Memory subsystem
    # ------------------------------------------------------------
    memory = MemorySS()
    memory.add_ram_banks([64])
    memory.add_linker_section(LinkerSection.by_size("code", 0, 0x00008000))
    memory.add_linker_section(LinkerSection("data", 0x00008000, None))

    # ------------------------------------------------------------
    # AXI slaves
    #
    # A slave with an AXI slave port becomes a direct crossbar slave window.
    # A peripheral subsystem is itself an AXI slave window whose
    # register-interface peripherals become REG slaves nested in it.
    # ------------------------------------------------------------
    bus.add_slave(BusSlave("mem", 0x00000000, memory.ram_size_address()))
    bus.add_slave(BusSlave("debug_module", 0x00010000, 0x00010000))

    peripherals = PeripheralSubsystem("Peripherals", 0x00020000, 0x10000000)
    peripherals.add_peripheral(SOC_ctrl(offset=0x00000000, length=0x00001000))
    peripherals.add_peripheral(Bootrom(offset=0x00010000, length=0x00010000))
    peripherals.add_peripheral(Fast_intr_ctrl(offset=0x00020000, length=0x00001000))
    peripherals.add_peripheral(UART(offset=0x00030000, length=0x00001000))
    peripherals.add_peripheral(Ext_peripheral(offset=0x00040000, length=0x00001000))
    bus.add_slave(peripherals)

    bus.add_slave(BusSlave("ext_slave", 0x10020000, 0x00010000))

    # ------------------------------------------------------------
    # System
    # ------------------------------------------------------------
    system = XAlp(bus)

    system.set_cpu(cva6())
    system.set_memory_ss(memory)

    return system
