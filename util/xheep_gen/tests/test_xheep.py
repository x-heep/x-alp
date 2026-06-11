# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for xheep.XHeep: configuration plumbing and system-level
validation rules."""

import pytest

from bus_type import BusType
from cpu.cv32e20 import cv32e20
from cpu.cv32e40p import cv32e40p
from cv_x_if import CvXIf
from memory_ss.memory_ss import MemorySS
from peripherals.base_peripherals_domain import BasePeripheralDomain
from peripherals.user_peripherals_domain import UserPeripheralDomain
from peripherals.user_peripherals import UART
from xheep import XHeep


def make_valid_memory() -> MemorySS:
    mem = MemorySS()
    mem.add_ram_banks([32], "code")
    mem.add_ram_banks([32], "data")
    return mem


def make_system(bus=BusType.onetoM) -> XHeep:
    """System with CPU and memory configured, no peripherals/padring."""
    system = XHeep(bus)
    system.set_cpu(cv32e20())
    system.set_memory_ss(make_valid_memory())
    return system


def make_base_domain(start=0x20000000, length=0x00100000) -> BasePeripheralDomain:
    """Base domain with all mandatory peripherals, as validate() requires."""
    domain = BasePeripheralDomain(start, length)
    domain.add_missing_peripherals()
    return domain


class TestConfigurationPlumbing:
    def test_bus_type_round_trip(self):
        system = XHeep(BusType.onetoM)
        assert system.bus_type() == BusType.onetoM
        system.set_bus_type(BusType.NtoM)
        assert system.bus_type() == BusType.NtoM

    def test_available_cpus(self):
        system = XHeep(BusType.onetoM)
        assert system.get_available_cpus() == [
            "cv32e20",
            "cv32e40p",
            "cv32e40px",
            "cv32e40x",
        ]

    def test_constructor_rejects_non_bus_type(self):
        with pytest.raises(TypeError):
            XHeep("onetoM")

    def test_set_cpu_rejects_wrong_type(self):
        with pytest.raises(TypeError):
            XHeep(BusType.onetoM).set_cpu("cv32e20")

    def test_set_memory_ss_rejects_wrong_type(self):
        with pytest.raises(TypeError):
            XHeep(BusType.onetoM).set_memory_ss({})

    def test_set_xif_rejects_wrong_type(self):
        with pytest.raises(TypeError):
            XHeep(BusType.onetoM).set_xif("xif")

    def test_add_peripheral_domain_rejects_unknown_type(self):
        with pytest.raises(ValueError):
            XHeep(BusType.onetoM).add_peripheral_domain("domain")


class TestPeripheralDomainIsolation:
    def test_added_domain_is_deep_copied(self):
        # Mutating the original domain after adding it must not leak
        # into the system: mcu_gen relies on this to keep configs stable.
        system = XHeep(BusType.onetoM)
        domain = UserPeripheralDomain()
        system.add_peripheral_domain(domain)
        domain.add_peripheral(UART())
        assert len(system.get_user_peripheral_domain().get_peripherals()) == 0

    def test_getter_returns_a_copy(self):
        system = XHeep(BusType.onetoM)
        system.add_peripheral_domain(UserPeripheralDomain())
        copy = system.get_user_peripheral_domain()
        copy.add_peripheral(UART())
        assert len(system.get_user_peripheral_domain().get_peripherals()) == 0

    def test_configured_flags(self):
        system = XHeep(BusType.onetoM)
        assert not system.are_peripherals_configured()
        system.add_peripheral_domain(make_base_domain())
        assert system.are_base_peripherals_configured()
        assert not system.are_peripherals_configured()
        system.add_peripheral_domain(UserPeripheralDomain())
        assert system.are_peripherals_configured()


class TestExtensions:
    def test_extension_round_trip(self):
        system = XHeep(BusType.onetoM)
        system.add_extension("serial_link", {"channels": 4})
        assert system.is_extension_defined("serial_link")
        assert system.get_extension("serial_link") == {"channels": 4}

    def test_missing_extension(self):
        system = XHeep(BusType.onetoM)
        assert not system.is_extension_defined("nope")
        assert system.get_extension("nope") is None


class TestValidate:
    def test_missing_cpu_rejected(self):
        system = XHeep(BusType.onetoM)
        with pytest.raises(RuntimeError, match="CPU must be configured"):
            system.validate()

    def test_missing_memory_rejected(self):
        system = XHeep(BusType.onetoM)
        system.set_cpu(cv32e20())
        with pytest.raises(RuntimeError, match="memory subsystem"):
            system.validate()

    def test_il_ram_requires_ntom_bus(self):
        system = make_system(bus=BusType.onetoM)
        system.memory_ss().add_ram_banks_il(2, 32)
        system.build()
        with pytest.raises(RuntimeError, match="interleaved"):
            system.validate()

    def test_il_ram_with_ntom_bus_passes_bus_check(self):
        system = make_system(bus=BusType.NtoM)
        system.memory_ss().add_ram_banks_il(2, 32)
        system.build()
        # Validation proceeds past the bus check and stops at the
        # missing padring instead.
        with pytest.raises(RuntimeError, match="padring"):
            system.validate()

    def test_xif_incompatible_with_cv32e40p(self):
        system = make_system()
        system.set_cpu(cv32e40p())
        system.set_xif(CvXIf())
        system.build()
        with pytest.raises(RuntimeError, match="CV-X-IF"):
            system.validate()

    def test_base_domain_overflowing_into_user_domain_rejected(self):
        system = make_system()
        # Base [0x20000000, 0x20100000) overlaps user starting at 0x20080000.
        system.add_peripheral_domain(make_base_domain(0x20000000, 0x00100000))
        system.add_peripheral_domain(UserPeripheralDomain(0x20080000, 0x00100000))
        system.build()
        with pytest.raises(RuntimeError, match="overflows over user"):
            system.validate()

    def test_user_domain_overflowing_into_base_domain_rejected(self):
        system = make_system()
        system.add_peripheral_domain(make_base_domain(0x20080000, 0x00100000))
        system.add_peripheral_domain(UserPeripheralDomain(0x20000000, 0x00100000))
        system.build()
        with pytest.raises(RuntimeError, match="overflows over base"):
            system.validate()

    def test_domains_with_same_start_rejected(self):
        system = make_system()
        system.add_peripheral_domain(make_base_domain(0x20000000, 0x00100000))
        system.add_peripheral_domain(UserPeripheralDomain(0x20000000, 0x00100000))
        system.build()
        with pytest.raises(RuntimeError, match="same address"):
            system.validate()

    def test_base_domain_below_0x10000_rejected(self):
        system = make_system()
        system.add_peripheral_domain(make_base_domain(0x8000, 0x00100000))
        system.add_peripheral_domain(UserPeripheralDomain())
        system.build()
        with pytest.raises(RuntimeError, match="0x10000"):
            system.validate()

    def test_missing_padring_rejected(self):
        system = make_system()
        system.add_peripheral_domain(make_base_domain())
        system.add_peripheral_domain(UserPeripheralDomain())
        system.build()
        with pytest.raises(RuntimeError, match="padring"):
            system.validate()

    def test_validate_with_only_base_domain_does_not_crash(self):
        system = make_system()
        system.add_peripheral_domain(make_base_domain())
        system.build()
        with pytest.raises(RuntimeError, match="padring"):
            system.validate()


class TestRemainingTypeChecks:
    def test_set_bus_type_rejects_wrong_type(self):
        with pytest.raises(TypeError):
            XHeep(BusType.onetoM).set_bus_type("NtoM")

    def test_set_padring_rejects_wrong_type(self):
        with pytest.raises(TypeError):
            XHeep(BusType.onetoM).set_padring("ring")

    def test_base_domain_low_start_address_rejected(self):
        system = XHeep(BusType.onetoM)
        system.set_cpu(cv32e20())
        mem = MemorySS()
        mem.add_ram_banks([32], "code")
        mem.add_ram_banks([32], "data")
        system.set_memory_ss(mem)
        domain = BasePeripheralDomain(start_address=0x8000)
        domain.add_missing_peripherals()
        system.add_peripheral_domain(domain)
        system.build()
        with pytest.raises(RuntimeError, match="0x10000"):
            system.validate()
