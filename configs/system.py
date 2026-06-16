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

from peripherals.abstractions import PeripheralDomain
from peripherals.base_peripherals import (
    SOC_ctrl,
    Bootrom,
    SPI_flash,
    SPI_memio,
    DMA,
    Power_manager,
    RV_timer_ao,
    Fast_intr_ctrl,
    Ext_peripheral,
)
from peripherals.user_peripherals import (
    UART,
)

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
    memory.add_ram_banks([64] * 2)
    memory.add_linker_section(LinkerSection.by_size("code", 0, 0x00008000))
    memory.add_linker_section(LinkerSection("data", 0x00008000, None))

    # ------------------------------------------------------------
    # AXI slaves
    #
    # A slave with an AXI slave port becomes a direct crossbar slave window.
    # ------------------------------------------------------------
    bus.add_slave(BusSlave("mem", 0x00000000, memory.ram_size_address()))
    bus.add_slave(BusSlave("debug_module"))
    bus.add_slave(BusSlave("ext_slave"))

    # ------------------------------------------------------------
    # System
    # ------------------------------------------------------------
    system = XAlp(bus)

    system.set_cpu(cva6())
    system.set_memory_ss(memory)

    # ------------------------------------------------------------
    # Peripheral subsystem
    #
    # Single always-on peripheral domain holding every peripheral. It is
    # an independent bus node: connected to the system (domain semantics)
    # and added as a bus slave (so its register-interface peripherals
    # become REG slaves in the address map).
    #
    # TODO: split into a configurable number of peripheral domains, each
    # with its own power domain / clock gating.
    # ------------------------------------------------------------
    peripherals = PeripheralDomain(
        "Peripherals",
        0x20000000,
        0x00100000,
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
    system.connect_peripheral_subsystem(peripherals)
    bus.add_slave(peripherals)

    return system
