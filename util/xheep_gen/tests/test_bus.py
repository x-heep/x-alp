# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for bus-level peripheral/domain address-map generation."""

import pytest

from bus import Bus
from bus_type import BusType
from peripherals.user_peripherals import GPIO, UART
from peripherals.user_peripherals_domain import UserPeripheralDomain


class TestBus:
    def test_constructor_rejects_non_bus_type(self):
        with pytest.raises(TypeError):
            Bus("NtoM")

    def test_flat_peripherals_generate_contiguous_address_map(self):
        uart = UART(length=0x100)
        gpio = GPIO(length=0x80)
        bus = Bus(BusType.NtoM, [uart, gpio])

        address_map = bus.generate_address_map(start_address=0x1000)

        assert address_map == [
            {
                "domain": None,
                "name": "uart",
                "address": 0x1000,
                "offset": 0x1000,
                "size": 0x100,
            },
            {
                "domain": None,
                "name": "gpio",
                "address": 0x1100,
                "offset": 0x1100,
                "size": 0x80,
            },
        ]
        # The bus owns a copy of the peripherals it was constructed with.
        assert uart.get_address() is None

    def test_flat_manual_and_auto_addresses_can_be_mixed(self):
        gpio = GPIO(0x2000, 0x100)
        uart = UART(length=0x100)
        spi = UART(length=0x80)
        bus = Bus(BusType.NtoM, [uart, gpio, spi])

        address_map = bus.generate_address_map(start_address=0x1000)

        assert [entry["address"] for entry in address_map] == [
            0x1000,
            0x2000,
            0x2100,
        ]

    def test_flat_fixed_address_overlap_is_rejected(self):
        bus = Bus(BusType.NtoM, [UART(0x1000, 0x100), GPIO(0x1080, 0x100)])

        with pytest.raises(ValueError, match="next free bus address"):
            bus.generate_address_map()

    def test_domains_generate_absolute_address_map(self):
        domain = UserPeripheralDomain(
            start_address=0x30000000,
            length=0x1000,
            peripherals=[UART(length=0x100), GPIO(length=0x80)],
        )
        bus = Bus(BusType.onetoM, [domain])

        address_map = bus.generate_address_map()

        assert address_map == [
            {
                "domain": "User Peripheral Domain",
                "name": "uart",
                "address": 0x30000000,
                "offset": 0x0,
                "size": 0x100,
            },
            {
                "domain": "User Peripheral Domain",
                "name": "gpio",
                "address": 0x30000100,
                "offset": 0x100,
                "size": 0x80,
            },
        ]

    def test_rejects_mixed_flat_peripheral_and_domain_list(self):
        domain = UserPeripheralDomain(peripherals=[UART()])

        with pytest.raises(TypeError, match="either all Peripheral"):
            Bus(BusType.NtoM, [domain, UART()])


class TestBusConfigurationErrors:
    def test_constructor_rejects_both_peripherals_and_domains(self):
        with pytest.raises(ValueError, match="not both"):
            Bus(
                BusType.NtoM,
                peripherals=[UART()],
                domains=[UserPeripheralDomain()],
            )

    def test_constructor_rejects_non_list_entries(self):
        with pytest.raises(TypeError, match="list"):
            Bus(BusType.NtoM, peripherals="uart")

    def test_set_peripherals_rejects_non_list(self):
        with pytest.raises(TypeError, match="list"):
            Bus(BusType.NtoM).set_peripherals(UART())

    def test_set_peripherals_rejects_non_peripheral_items(self):
        with pytest.raises(TypeError, match="only Peripheral"):
            Bus(BusType.NtoM).set_peripherals([UART(), "gpio"])

    def test_set_domains_rejects_non_list(self):
        with pytest.raises(TypeError, match="list"):
            Bus(BusType.NtoM).set_domains(UserPeripheralDomain())

    def test_set_domains_rejects_non_domain_items(self):
        with pytest.raises(TypeError, match="only PeripheralDomain"):
            Bus(BusType.NtoM).set_domains([UserPeripheralDomain(), UART()])

    def test_add_peripheral_rejects_wrong_type(self):
        with pytest.raises(TypeError, match="Peripheral"):
            Bus(BusType.NtoM).add_peripheral("uart")

    def test_add_peripheral_rejects_domain_configured_bus(self):
        bus = Bus(BusType.NtoM, domains=[UserPeripheralDomain()])
        with pytest.raises(ValueError, match="configured with domains"):
            bus.add_peripheral(UART())

    def test_add_domain_rejects_wrong_type(self):
        with pytest.raises(TypeError, match="PeripheralDomain"):
            Bus(BusType.NtoM).add_domain(UART())

    def test_add_domain_rejects_peripheral_configured_bus(self):
        bus = Bus(BusType.NtoM, peripherals=[UART()])
        with pytest.raises(ValueError, match="configured with peripherals"):
            bus.add_domain(UserPeripheralDomain())

    def test_generate_address_map_rejects_negative_start(self):
        with pytest.raises(ValueError, match="positive"):
            Bus(BusType.NtoM).generate_address_map(-1)


class TestBusAccessors:
    def test_bus_type(self):
        assert Bus(BusType.NtoM).bus_type() == BusType.NtoM

    def test_add_peripheral_and_domain_happy_paths(self):
        flat = Bus(BusType.NtoM)
        flat.add_peripheral(UART())
        assert [p.get_name() for p in flat.get_peripherals()] == ["uart"]

        nested = Bus(BusType.NtoM)
        nested.add_domain(UserPeripheralDomain(peripherals=[GPIO()]))
        assert len(nested.get_domains()) == 1

    def test_get_all_peripherals_flat_and_domains(self):
        flat = Bus(BusType.NtoM, [UART()])
        assert [p.get_name() for p in flat.get_all_peripherals()] == ["uart"]

        nested = Bus(
            BusType.NtoM, domains=[UserPeripheralDomain(peripherals=[UART(), GPIO()])]
        )
        assert [p.get_name() for p in nested.get_all_peripherals()] == ["uart", "gpio"]

    def test_get_address_map_skips_unplaced_domain_peripherals(self):
        bus = Bus(BusType.NtoM, domains=[UserPeripheralDomain(peripherals=[UART()])])
        # Without build() the peripheral has no address yet.
        assert bus.get_address_map() == []

    def test_flat_overlap_detected_by_validator(self):
        bus = Bus(BusType.NtoM)
        # Out-of-order fixed addresses pass the sequential placement check,
        # so the overlap is only caught by the final sorted validation.
        bus._peripherals = [UART(0x1000, 0x100), GPIO(0x1080, 0x100)]
        with pytest.raises(ValueError, match="overflows"):
            bus._validate_flat_address_map()
