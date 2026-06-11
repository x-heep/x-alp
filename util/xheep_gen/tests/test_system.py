# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for system.System: subsystem management, extensions, build and
the system-level validation rules."""

import pytest

from bus_type import BusType
from cpu.cv32e20 import cv32e20
from memory_ss.memory_ss import MemorySS
from pads.dimension import Dimension
from pads.floorplan import FloorplanDimensions, Side
from pads.pad_ring import PadRing
from pads.pin import Input
from peripherals.base_peripherals_domain import BasePeripheralDomain
from peripherals.peripheral_subsystem import PeripheralSubsystem
from peripherals.user_peripherals import UART
from peripherals.user_peripherals_domain import UserPeripheralDomain
from system import System


def make_memory():
    mem = MemorySS()
    mem.add_ram_banks([32], "code")
    mem.add_ram_banks([32], "data")
    return mem


def make_padring():
    pin = Input("clk")
    floorplan = FloorplanDimensions(
        Dimension(3000, 3000),
        {side: 5 for side in Side},
        {side: 10 for side in Side},
        {side: 20 for side in Side},
    )
    return PadRing(floorplan, {Side.LEFT: [[pin]]}, [pin], {})


def make_subsystem(name="Test", start=0x40000000, length=0x00100000):
    subsystem = PeripheralSubsystem(name, start, length)
    subsystem.add_peripheral(UART())
    return subsystem


def make_system():
    system = System(BusType.onetoM)
    system.set_cpu(cv32e20())
    system.set_memory_ss(make_memory())
    return system


class TestSubsystemManagement:
    def test_add_rejects_wrong_type(self):
        with pytest.raises(TypeError):
            System(BusType.onetoM).add_peripheral_subsystem("subsystem")

    def test_add_rejects_duplicate_name(self):
        system = System(BusType.onetoM)
        system.add_peripheral_subsystem(make_subsystem())
        with pytest.raises(ValueError, match="already present"):
            system.add_peripheral_subsystem(make_subsystem())

    def test_added_subsystem_is_deep_copied(self):
        system = System(BusType.onetoM)
        subsystem = make_subsystem()
        system.add_peripheral_subsystem(subsystem)
        subsystem.set_power_domain("changed")
        retrieved = system.get_peripheral_subsystem("Test Peripheral Domain")
        assert retrieved.get_power_domain() is None

    def test_get_unknown_subsystem_returns_none(self):
        assert System(BusType.onetoM).get_peripheral_subsystem("Nope") is None

    def test_get_peripheral_subsystems_returns_copies(self):
        system = System(BusType.onetoM)
        system.add_peripheral_subsystem(make_subsystem())
        copies = system.get_peripheral_subsystems()
        assert len(copies) == 1
        copies[0].set_power_domain("changed")
        assert (
            system.get_peripheral_subsystem("Test Peripheral Domain").get_power_domain()
            is None
        )

    def test_remove_subsystem(self):
        system = System(BusType.onetoM)
        system.add_peripheral_subsystem(make_subsystem())
        system.remove_peripheral_subsystem("Test Peripheral Domain")
        assert system.get_peripheral_subsystems() == []

    def test_remove_unknown_subsystem_warns(self, capsys):
        System(BusType.onetoM).remove_peripheral_subsystem("Nope")
        assert "Warning" in capsys.readouterr().out

    def test_configured_peripheral_names(self):
        system = System(BusType.onetoM)
        system.add_peripheral_subsystem(make_subsystem())
        assert system.get_configured_peripheral_names() == ["uart"]


class TestDomainAccessors:
    def test_base_and_user_domain_lookup(self):
        system = System(BusType.onetoM)
        assert system.get_base_peripheral_domain() is None
        assert system.get_user_peripheral_domain() is None
        assert not system.are_peripherals_configured()

        base = BasePeripheralDomain()
        base.add_missing_peripherals()
        system.add_peripheral_subsystem(base)
        system.add_peripheral_subsystem(UserPeripheralDomain(peripherals=[UART()]))

        assert isinstance(system.get_base_peripheral_domain(), BasePeripheralDomain)
        assert isinstance(system.get_user_peripheral_domain(), UserPeripheralDomain)
        assert system.are_peripherals_configured()


class TestPadRingAndExtensions:
    def test_padring_round_trip(self):
        system = System(BusType.onetoM)
        ring = make_padring()
        system.set_padring(ring)
        assert system.get_padring() is ring

    def test_set_padring_rejects_wrong_type(self):
        with pytest.raises(TypeError):
            System(BusType.onetoM).set_padring("ring")

    def test_extensions(self):
        system = System(BusType.onetoM)
        system.add_extension("accel", {"lanes": 4})
        assert system.is_extension_defined("accel")
        assert system.get_extension("accel") == {"lanes": 4}
        assert system.get_extension("missing") is None
        assert not system.is_extension_defined("missing")


class TestTypeChecks:
    def test_constructor_rejects_non_bus_type(self):
        with pytest.raises(TypeError):
            System("onetoM")

    def test_setters_reject_wrong_types(self):
        system = System(BusType.onetoM)
        with pytest.raises(TypeError):
            system.set_bus_type("NtoM")
        with pytest.raises(TypeError):
            system.set_cpu("cv32e20")
        with pytest.raises(TypeError):
            system.set_xif("xif")
        with pytest.raises(TypeError):
            system.set_memory_ss("memory")


class TestBuildAndValidate:
    def test_build_builds_memory_and_subsystems(self):
        system = make_system()
        subsystem = PeripheralSubsystem("Test", 0x40000000, 0x00100000)
        subsystem.add_peripheral(UART())
        system.add_peripheral_subsystem(subsystem)
        system.build()
        placed = system.get_peripheral_subsystem("Test Peripheral Domain")
        assert placed.get_peripherals()[0].get_address() == 0x0

    def test_validate_passes_with_minimal_system(self):
        system = make_system()
        system.add_peripheral_subsystem(make_subsystem())
        system.set_padring(make_padring())
        system.build()
        assert system.validate() is True

    def test_missing_cpu_rejected(self):
        system = System(BusType.onetoM)
        with pytest.raises(RuntimeError, match="CPU"):
            system.validate()

    def test_missing_memory_rejected(self):
        system = System(BusType.onetoM)
        system.set_cpu(cv32e20())
        with pytest.raises(RuntimeError, match="memory"):
            system.validate()

    def test_missing_padring_rejected(self):
        system = make_system()
        system.build()
        with pytest.raises(RuntimeError, match="padring"):
            system.validate()

    def test_same_start_address_rejected(self):
        system = make_system()
        system.add_peripheral_subsystem(make_subsystem(name="A"))
        system.add_peripheral_subsystem(make_subsystem(name="B"))
        system.build()
        with pytest.raises(RuntimeError, match="same address"):
            system.validate()

    def test_overlapping_subsystems_rejected(self):
        system = make_system()
        system.add_peripheral_subsystem(
            make_subsystem(name="A", start=0x40000000, length=0x00200000)
        )
        system.add_peripheral_subsystem(make_subsystem(name="B", start=0x40100000))
        system.build()
        with pytest.raises(RuntimeError, match="overflows"):
            system.validate()

    def test_low_start_address_rejected(self):
        system = make_system()
        system.add_peripheral_subsystem(make_subsystem(start=0x8000))
        system.build()
        with pytest.raises(RuntimeError, match="0x10000"):
            system.validate()

    def test_xif_incompatible_with_cv32e40p(self):
        from cpu.cv32e40p import cv32e40p
        from cv_x_if import CvXIf

        system = System(BusType.onetoM)
        system.set_cpu(cv32e40p())
        system.set_memory_ss(make_memory())
        system.set_xif(CvXIf())
        system.build()
        with pytest.raises(RuntimeError, match="CV-X-IF"):
            system.validate()

    def test_il_ram_requires_compatible_bus(self):
        system = System(BusType.onetoM)
        system.set_cpu(cv32e20())
        mem = make_memory()
        mem.add_ram_banks_il(2, 32, "il")
        system.set_memory_ss(mem)
        system.build()
        with pytest.raises(RuntimeError, match="interleaved"):
            system.validate()


class TestFlavorConstants:
    class Flavor(System):
        AVAILABLE_CPUS = ["cv32e20"]
        AVAILABLE_PERIPHERALS = ["uart"]
        MINIMUM_PERIPHERALS = ["uart", "gpio"]

    def make_flavor(self):
        system = self.Flavor(BusType.onetoM)
        system.set_cpu(cv32e20())
        system.set_memory_ss(make_memory())
        system.set_padring(make_padring())
        return system

    def test_constant_accessors(self):
        system = self.make_flavor()
        assert system.get_available_cpus() == ["cv32e20"]
        assert system.get_available_peripherals() == ["uart"]
        assert system.get_minimum_peripherals() == ["uart", "gpio"]

    def test_unavailable_cpu_rejected(self):
        from cpu.cv32e40p import cv32e40p

        system = self.make_flavor()
        system.set_cpu(cv32e40p())
        system.build()
        with pytest.raises(RuntimeError, match="not available"):
            system.validate()

    def test_unsupported_peripheral_rejected(self):
        system = self.make_flavor()
        subsystem = PeripheralSubsystem("Test", 0x40000000, 0x00100000)
        from peripherals.user_peripherals import I2C

        subsystem.add_peripheral(I2C())
        system.add_peripheral_subsystem(subsystem)
        system.build()
        with pytest.raises(RuntimeError, match="Unsupported"):
            system.validate()

    def test_missing_minimum_peripheral_rejected(self):
        system = self.make_flavor()
        system.add_peripheral_subsystem(make_subsystem())
        system.build()
        with pytest.raises(RuntimeError, match="Missing minimum"):
            system.validate()


class TestBusTypeRoundTrip:
    def test_set_and_get(self):
        system = System(BusType.onetoM)
        system.set_bus_type(BusType.NtoM)
        assert system.bus_type() == BusType.NtoM
