# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for peripherals.abstractions.PeripheralDomain: automatic address
placement (build) and overlap validation."""

import pytest

from peripherals.abstractions import PeripheralDomain
from peripherals.base_peripherals import DMA, Power_manager
from peripherals.base_peripherals_domain import BasePeripheralDomain
from peripherals.user_peripherals import GPIO, I2C, PDM2PCM, UART
from peripherals.user_peripherals_domain import UserPeripheralDomain

PERIPH_64K = 0x10000


def make_domain(**kwargs):
    return PeripheralDomain(
        name="Test", start_address=0x40000000, length=0x00100000, **kwargs
    )


class TestDomainMembership:
    def test_constructor_accepts_initial_peripherals(self):
        domain = UserPeripheralDomain(peripherals=[UART(), GPIO()])
        assert [p.get_name() for p in domain.get_peripherals()] == ["uart", "gpio"]

    def test_constructor_rejects_initial_peripheral_of_wrong_type(self):
        with pytest.raises(ValueError):
            BasePeripheralDomain(peripherals=[UART()])

    def test_base_domain_rejects_user_peripheral(self):
        with pytest.raises(ValueError):
            BasePeripheralDomain().add_peripheral(UART())

    def test_user_domain_rejects_base_peripheral(self):
        with pytest.raises(ValueError):
            UserPeripheralDomain().add_peripheral(DMA())

    def test_contains_peripheral(self):
        domain = UserPeripheralDomain()
        domain.add_peripheral(UART())
        assert domain.contains_peripheral("uart")
        assert not domain.contains_peripheral("gpio")

    def test_get_peripherals_returns_copies(self):
        domain = UserPeripheralDomain()
        domain.add_peripheral(UART())
        domain.get_peripherals()[0].set_address(0xDEAD0000)
        assert domain.get_peripherals()[0].get_address() is None


class TestBuildPlacement:
    def test_auto_placement_assigns_disjoint_addresses(self):
        domain = UserPeripheralDomain()
        for p in (UART(), GPIO(), I2C()):
            domain.add_peripheral(p)
        domain.build()

        addresses = sorted(p.get_address() for p in domain.get_peripherals())
        assert addresses == [0x0, PERIPH_64K, 2 * PERIPH_64K]
        domain.validate()

    def test_fixed_address_is_respected(self):
        domain = UserPeripheralDomain()
        domain.add_peripheral(UART(0x40000))
        domain.build()
        assert domain.get_peripherals()[0].get_address() == 0x40000

    def test_auto_peripherals_fill_gap_before_fixed_one(self):
        # Fixed peripheral occupies [0x10000, 0x20000); the two automatic
        # ones must use the hole at 0x0 and the space after the fixed one.
        domain = UserPeripheralDomain()
        domain.add_peripheral(UART(PERIPH_64K))
        domain.add_peripheral(GPIO())
        domain.add_peripheral(I2C())
        domain.build()

        addresses = sorted(p.get_address() for p in domain.get_peripherals())
        assert addresses == [0x0, PERIPH_64K, 2 * PERIPH_64K]
        domain.validate()

    def test_larger_peripherals_are_placed_first(self):
        # The big peripheral only fits in the hole between the two fixed
        # ones if it is placed before the small ones grab the space.
        domain = UserPeripheralDomain(0x30000000, 0x80000)
        domain.add_peripheral(UART(0x0))
        domain.add_peripheral(GPIO(0x60000))
        domain.add_peripheral(I2C(None, 0x40000))  # big: fits only at 0x10000
        domain.add_peripheral(UART(None, 0x10000))
        domain.build()

        by_addr = {p.get_address(): p for p in domain.get_peripherals()}
        assert by_addr[0x10000].get_length() == 0x40000
        assert 0x50000 in by_addr or 0x70000 in by_addr
        domain.validate()

    def test_no_space_left_rejected(self):
        # Domain fits exactly two 64KiB peripherals.
        domain = UserPeripheralDomain(0x30000000, 2 * PERIPH_64K)
        for _ in range(3):
            domain.add_peripheral(UART())
        with pytest.raises(ValueError, match="free space"):
            domain.build()

    def test_fixed_peripheral_past_domain_end_rejected(self):
        domain = UserPeripheralDomain(0x30000000, 0x100000)
        domain.add_peripheral(UART(0xF8000, 0x10000))
        with pytest.raises(ValueError, match="ends after"):
            domain.build()

    def test_overlapping_fixed_peripherals_rejected(self):
        domain = UserPeripheralDomain()
        domain.add_peripheral(UART(0x0))
        domain.add_peripheral(GPIO(0x8000))
        with pytest.raises(ValueError, match="starts in"):
            domain.build()


class TestValidate:
    def test_overlapping_addresses_rejected(self):
        domain = UserPeripheralDomain()
        domain.add_peripheral(UART(0x0))
        domain.add_peripheral(GPIO(0x8000))
        with pytest.raises(RuntimeError, match="overflows"):
            domain.validate()

    def test_peripheral_past_domain_end_rejected(self):
        domain = UserPeripheralDomain(0x30000000, 0x100000)
        domain.add_peripheral(UART(0xF8000, 0x10000))
        with pytest.raises(RuntimeError, match="out of the domain"):
            domain.validate()

    def test_empty_domain_is_valid(self):
        UserPeripheralDomain().validate()

    def test_valid_layout_passes(self):
        domain = UserPeripheralDomain()
        domain.add_peripheral(UART(0x0))
        domain.add_peripheral(GPIO(PERIPH_64K))
        domain.validate()


class TestBaseDomainDefaults:
    def test_add_missing_peripherals_completes_the_domain(self):
        domain = BasePeripheralDomain()
        domain.add_peripheral(DMA())
        domain.add_missing_peripherals()
        names = {p.get_name() for p in domain.get_peripherals()}
        # All mandatory always-on peripherals must be present.
        assert "dma" in names
        assert "soc_ctrl" in names
        assert "bootrom" in names
        # DMA was already there: it must not be duplicated.
        assert sum(1 for p in domain.get_peripherals() if p.get_name() == "dma") == 1


class TestPeripheralApi:
    def test_manual_and_auto_start_address_helpers(self):
        peripheral = UART()
        assert peripheral.has_auto_start_address()
        assert peripheral.get_start_address() is None

        peripheral.set_start_address(0x2000)
        assert not peripheral.has_auto_start_address()
        assert peripheral.get_start_address() == 0x2000

        peripheral.use_auto_start_address()
        assert peripheral.has_auto_start_address()
        assert peripheral.get_start_address() is None

    def test_manual_start_address_rejects_invalid_values(self):
        with pytest.raises(ValueError, match="positive integer"):
            UART().set_start_address(-1)

    def test_size_bytes_matches_length(self):
        peripheral = UART(length=0x1234)
        assert peripheral.get_size_bytes() == 0x1234

    def test_default_port_configuration(self):
        peripheral = UART()
        assert not peripheral.has_master_ports()
        assert peripheral.get_num_master_ports() == 0
        assert not peripheral.has_slave_ports()
        assert peripheral.get_num_slave_ports() == 0
        assert peripheral.has_reg_if_ports()
        assert peripheral.has_register_interface_ports()
        assert peripheral.get_num_reg_if_ports() == 1
        assert peripheral.get_num_register_interface_ports() == 1

    def test_port_configuration_override(self):
        peripheral = UART(
            has_master_ports=True,
            num_master_ports=2,
            has_slave_ports=True,
            num_slave_ports=1,
            has_reg_if_ports=False,
            num_reg_if_ports=0,
        )

        assert peripheral.has_master_ports()
        assert peripheral.get_num_master_ports() == 2
        assert peripheral.has_slave_ports()
        assert peripheral.get_num_slave_ports() == 1
        assert not peripheral.has_reg_if_ports()
        assert peripheral.get_num_reg_if_ports() == 0

    def test_disabled_ports_must_have_zero_count(self):
        with pytest.raises(ValueError, match="zero when disabled"):
            UART(has_master_ports=False, num_master_ports=1)

    def test_enabled_ports_must_have_nonzero_count(self):
        with pytest.raises(ValueError, match="greater than zero"):
            UART(has_slave_ports=True, num_slave_ports=0)

    def test_custom_peripheral_constructors_accept_common_port_config(self):
        pdm = PDM2PCM(has_slave_ports=True, num_slave_ports=1)
        power = Power_manager(has_reg_if_ports=False, num_reg_if_ports=0)
        dma = DMA(num_channels=2, num_master_ports=2)

        assert pdm.has_slave_ports()
        assert pdm.get_num_slave_ports() == 1
        assert not power.has_reg_if_ports()
        assert dma.has_master_ports()
        assert dma.get_num_master_ports() == 2


class TestConstruction:
    def test_name_gets_domain_suffix(self):
        assert make_domain().get_name() == "Test Peripheral Domain"

    def test_defaults_are_always_on(self):
        domain = make_domain()
        assert domain.get_power_domain() is None
        assert domain.is_always_on()
        assert not domain.has_power_domain()
        assert not domain.has_clock_gating()

    def test_invalid_power_domain_type_rejected(self):
        with pytest.raises(TypeError, match="power_domain"):
            make_domain(power_domain=42)

    def test_invalid_clock_gating_type_rejected(self):
        with pytest.raises(TypeError, match="clock_gating"):
            make_domain(clock_gating="yes")


class TestPowerAndClock:
    def test_power_domain_round_trip(self):
        domain = make_domain()
        domain.set_power_domain("island")
        assert domain.get_power_domain() == "island"
        assert domain.has_power_domain()
        assert not domain.is_always_on()
        domain.set_power_domain(None)
        assert domain.is_always_on()

    def test_set_power_domain_rejects_wrong_type(self):
        with pytest.raises(TypeError, match="power_domain"):
            make_domain().set_power_domain(42)

    def test_clock_gating_round_trip(self):
        domain = make_domain()
        domain.set_clock_gating(True)
        assert domain.has_clock_gating()

    def test_set_clock_gating_rejects_wrong_type(self):
        with pytest.raises(TypeError, match="clock_gating"):
            make_domain().set_clock_gating("yes")


class TestMembership:
    def test_add_and_remove(self):
        domain = make_domain()
        uart = UART()
        domain.add_peripheral(uart)
        assert domain.contains_peripheral("uart")
        domain.remove_peripheral(uart)
        assert not domain.contains_peripheral("uart")

    def test_add_rejects_non_peripheral(self):
        with pytest.raises(ValueError):
            make_domain().add_peripheral("uart")

    def test_remove_unknown_warns(self, capsys):
        make_domain().remove_peripheral(UART())
        assert "Warning" in capsys.readouterr().out


class TestUserPeripheralDomain:
    def test_get_pdm2pcm(self):
        domain = UserPeripheralDomain()
        assert domain.get_pdm2pcm() is None
        pdm = PDM2PCM()
        domain.add_peripheral(pdm)
        domain.add_peripheral(GPIO())
        assert isinstance(domain.get_pdm2pcm(), PDM2PCM)

    def test_remove_peripheral(self):
        domain = UserPeripheralDomain()
        uart = UART()
        domain.add_peripheral(uart)
        domain.remove_peripheral(uart)
        assert not domain.contains_peripheral("uart")

    def test_remove_unknown_warns(self, capsys):
        UserPeripheralDomain().remove_peripheral(UART())
        assert "Warning" in capsys.readouterr().out


class TestBasePeripheralDomain:
    def test_remove_peripheral(self):
        domain = BasePeripheralDomain()
        dma = DMA()
        domain.add_peripheral(dma)
        domain.remove_peripheral(dma)
        assert not domain.contains_peripheral("dma")

    def test_remove_unknown_warns(self, capsys):
        BasePeripheralDomain().remove_peripheral(DMA())
        assert "Warning" in capsys.readouterr().out

    def test_get_all_dmas_and_get_dma(self):
        domain = BasePeripheralDomain()
        domain.add_peripheral(DMA())
        domain.add_peripheral(DMA())
        assert len(domain.get_all_dmas()) == 2
        assert domain.get_dma().get_name() == "dma"

    def test_get_all_dmas_without_dma_rejected(self):
        with pytest.raises(ValueError, match="DMA"):
            BasePeripheralDomain().get_all_dmas()

    def test_get_power_manager(self):
        domain = BasePeripheralDomain()
        domain.add_missing_peripherals()
        assert isinstance(domain.get_power_manager(), Power_manager)

    def test_get_power_manager_missing_rejected(self):
        with pytest.raises(ValueError, match="Power_manager"):
            BasePeripheralDomain().get_power_manager()

    def test_validate_reports_missing_peripherals(self):
        domain = BasePeripheralDomain()
        domain.add_peripheral(DMA())
        with pytest.raises(RuntimeError, match="Missing base peripherals"):
            domain.validate()


class TestSmallPeripherals:
    def test_power_manager_external_domains(self):
        pm = Power_manager(external_domains=2)
        assert pm.get_external_domains() == 2
        pm.set_external_domains(4)
        assert pm.get_external_domains() == 4

    def test_power_manager_too_many_external_domains(self):
        with pytest.raises(ValueError, match="external_domains"):
            Power_manager(external_domains=33)

    def test_pdm2pcm_cic_mode(self):
        assert PDM2PCM().get_cic_mode() is True
        assert PDM2PCM(cic_only=False).get_cic_mode() is False
