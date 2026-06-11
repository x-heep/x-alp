# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for peripherals.abstractions.Peripheral: address handling and
port-count normalization."""

import pytest

from peripherals.user_peripherals import UART
from peripherals.user_peripherals_domain import UserPeripheralDomain


class TestPortNormalization:
    def test_defaults(self):
        uart = UART()
        assert not uart.has_master_ports()
        assert uart.get_num_master_ports() == 0
        assert not uart.has_slave_ports()
        assert uart.get_num_slave_ports() == 0
        assert uart.has_reg_if_ports()
        assert uart.has_register_interface_ports()
        assert uart.get_num_reg_if_ports() == 1
        assert uart.get_num_register_interface_ports() == 1

    def test_enabled_flag_must_be_bool(self):
        with pytest.raises(TypeError, match="bool"):
            UART(has_master_ports="yes")

    def test_count_must_be_int(self):
        with pytest.raises(TypeError, match="int"):
            UART(has_master_ports=True, num_master_ports="2")

    def test_count_must_be_positive(self):
        with pytest.raises(ValueError, match="positive"):
            UART(has_master_ports=True, num_master_ports=-1)

    def test_enabled_with_zero_count_rejected(self):
        with pytest.raises(ValueError, match="greater than zero"):
            UART(has_master_ports=True, num_master_ports=0)

    def test_disabled_with_nonzero_count_rejected(self):
        with pytest.raises(ValueError, match="zero when disabled"):
            UART(has_master_ports=False, num_master_ports=2)


class TestAddressHandling:
    def test_address_round_trip(self):
        uart = UART()
        assert uart.has_auto_start_address()
        uart.set_start_address(0x1000)
        assert uart.get_start_address() == 0x1000
        assert not uart.has_auto_start_address()
        uart.use_auto_start_address()
        assert uart.get_address() is None

    def test_set_address_rejects_invalid_values(self):
        uart = UART()
        with pytest.raises(ValueError, match="positive"):
            uart.set_address(-1)
        with pytest.raises(ValueError, match="positive"):
            uart.set_address("0x1000")

    def test_negative_constructor_offset_is_ignored(self):
        assert UART(-5).get_address() is None

    def test_size_accessors(self):
        uart = UART(length=0x100)
        assert uart.get_length() == 0x100
        assert uart.get_size_bytes() == 0x100


class TestDomainConstruction:
    def test_initial_peripherals_must_be_a_list(self):
        with pytest.raises(TypeError, match="list"):
            UserPeripheralDomain(peripherals=UART())
