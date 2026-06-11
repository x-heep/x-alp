# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for xalp.XAlp bus-centric configuration and validation hooks."""

import pytest

from bus import Bus
from bus_type import BusType
from cpu.cv32e20 import cv32e20
from cpu.cv32e40x import cv32e40x
from cpu.cva6 import cva6
from memory_ss.memory_ss import MemorySS
from peripherals.abstractions import UserPeripheral
from peripherals.base_peripherals import SOC_ctrl
from peripherals.abstractions import PeripheralDomain
from xalp import XAlp
from xheep import XHeep


class UnsupportedPeripheral(UserPeripheral):
    _name = "unsupported"


def make_valid_memory() -> MemorySS:
    mem = MemorySS()
    mem.add_ram_banks([32], "code")
    mem.add_ram_banks([32], "data")
    return mem


def make_xalp() -> XAlp:
    system = XAlp(Bus(BusType.NtoM))
    system.set_cpu(cva6())
    system.set_memory_ss(make_valid_memory())
    return system


class TestConfigurationPlumbing:
    def test_bus_round_trip(self):
        bus = Bus(BusType.NtoM)
        system = XAlp(bus)
        assert system.bus().bus_type() == BusType.NtoM

    def test_constructor_rejects_non_bus(self):
        with pytest.raises(TypeError):
            XAlp(BusType.NtoM)

    def test_available_cpus_are_system_specific(self):
        assert XAlp(Bus(BusType.NtoM)).get_available_cpus() == ["cva6"]
        assert (
            XAlp(Bus(BusType.NtoM)).get_available_cpus()
            != XHeep(BusType.NtoM).get_available_cpus()
        )


class TestValidate:
    def test_unavailable_cpu_is_rejected(self):
        system = XAlp(Bus(BusType.NtoM))
        system.set_cpu(cv32e20())

        with pytest.raises(RuntimeError, match="not available"):
            system.validate()

    def test_missing_minimum_peripheral_is_rejected(self):
        system = make_xalp()

        with pytest.raises(RuntimeError, match="Missing minimum peripherals"):
            system.validate()

    def test_bus_peripherals_satisfy_minimum_peripherals(self):
        system = XAlp(Bus(BusType.NtoM, [SOC_ctrl()]))
        system.set_cpu(cva6())
        system.set_memory_ss(make_valid_memory())

        system.build()

        with pytest.raises(RuntimeError, match="padring"):
            system.validate()

    def test_unsupported_peripheral_is_rejected(self):
        system = make_xalp()
        system.connect_peripheral_subsystem(
            PeripheralDomain(
                "Unsupported",
                0x20000000,
                0x10000,
                peripherals=[UnsupportedPeripheral()],
            )
        )
        system.build()

        with pytest.raises(RuntimeError, match="Unsupported peripherals"):
            system.validate()


class TestBusConnectionAliases:
    def test_connect_cpu_and_memory(self):
        system = XAlp(Bus(BusType.NtoM))
        system.connect_cpu(cv32e40x())
        system.connect_memory_ss(make_valid_memory())
        assert system.cpu().get_name() == "cv32e40x"
        assert system.memory_ss().ram_numbanks() == 2

    def test_disconnect_peripheral_subsystem(self):
        system = make_xalp()
        system.connect_peripheral_subsystem(
            PeripheralDomain("Test", 0x20000000, 0x10000)
        )
        system.disconnect_peripheral_subsystem("Test Peripheral Domain")
        assert system.get_peripheral_subsystems() == []


class TestPowerDomainGrouping:
    def make_system_with_domains(self):
        system = make_xalp()
        system.connect_peripheral_subsystem(
            PeripheralDomain("AlwaysOn", 0x20000000, 0x10000)
        )
        system.connect_peripheral_subsystem(
            PeripheralDomain(
                "GatedA", 0x20010000, 0x10000, power_domain="island", clock_gating=True
            )
        )
        system.connect_peripheral_subsystem(
            PeripheralDomain("GatedB", 0x20020000, 0x10000, power_domain="island")
        )
        return system

    def test_get_power_domains(self):
        domains = self.make_system_with_domains().get_power_domains()
        assert list(domains.keys()) == ["island"]
        assert sorted(ss.get_name() for ss in domains["island"]) == [
            "GatedA Peripheral Domain",
            "GatedB Peripheral Domain",
        ]

    def test_get_always_on_subsystems(self):
        always_on = self.make_system_with_domains().get_always_on_subsystems()
        assert [ss.get_name() for ss in always_on] == ["AlwaysOn Peripheral Domain"]

    def test_get_clock_gated_subsystems(self):
        gated = self.make_system_with_domains().get_clock_gated_subsystems()
        assert [ss.get_name() for ss in gated] == ["GatedA Peripheral Domain"]
