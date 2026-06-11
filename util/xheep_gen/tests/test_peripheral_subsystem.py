# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for peripherals.peripheral_subsystem.PeripheralSubsystem and the
domain-specific helpers of the base/user domains and small peripherals."""

import pytest

from peripherals.base_peripherals import DMA, Power_manager
from peripherals.base_peripherals_domain import BasePeripheralDomain
from peripherals.peripheral_subsystem import PeripheralSubsystem
from peripherals.user_peripherals import GPIO, PDM2PCM, UART
from peripherals.user_peripherals_domain import UserPeripheralDomain


def make_subsystem(**kwargs):
    return PeripheralSubsystem(
        name="Test", start_address=0x40000000, length=0x00100000, **kwargs
    )


class TestConstruction:
    def test_name_gets_domain_suffix(self):
        assert make_subsystem().get_name() == "Test Peripheral Domain"

    def test_defaults_are_always_on(self):
        subsystem = make_subsystem()
        assert subsystem.get_power_domain() is None
        assert subsystem.is_always_on()
        assert not subsystem.has_power_domain()
        assert not subsystem.has_clock_gating()

    def test_invalid_power_domain_type_rejected(self):
        with pytest.raises(TypeError, match="power_domain"):
            make_subsystem(power_domain=42)

    def test_invalid_clock_gating_type_rejected(self):
        with pytest.raises(TypeError, match="clock_gating"):
            make_subsystem(clock_gating="yes")


class TestPowerAndClock:
    def test_power_domain_round_trip(self):
        subsystem = make_subsystem()
        subsystem.set_power_domain("island")
        assert subsystem.get_power_domain() == "island"
        assert subsystem.has_power_domain()
        assert not subsystem.is_always_on()
        subsystem.set_power_domain(None)
        assert subsystem.is_always_on()

    def test_set_power_domain_rejects_wrong_type(self):
        with pytest.raises(TypeError, match="power_domain"):
            make_subsystem().set_power_domain(42)

    def test_clock_gating_round_trip(self):
        subsystem = make_subsystem()
        subsystem.set_clock_gating(True)
        assert subsystem.has_clock_gating()

    def test_set_clock_gating_rejects_wrong_type(self):
        with pytest.raises(TypeError, match="clock_gating"):
            make_subsystem().set_clock_gating("yes")


class TestMembership:
    def test_add_and_remove(self):
        subsystem = make_subsystem()
        uart = UART()
        subsystem.add_peripheral(uart)
        assert subsystem.contains_peripheral("uart")
        subsystem.remove_peripheral(uart)
        assert not subsystem.contains_peripheral("uart")

    def test_add_rejects_non_peripheral(self):
        with pytest.raises(ValueError):
            make_subsystem().add_peripheral("uart")

    def test_remove_unknown_warns(self, capsys):
        make_subsystem().remove_peripheral(UART())
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

    def test_add_missing_peripherals_skips_existing(self):
        domain = BasePeripheralDomain()
        domain.add_peripheral(DMA(num_channels=2, num_channels_per_master_port=2))
        domain.add_missing_peripherals()
        names = [p.get_name() for p in domain.get_peripherals()]
        assert names.count("dma") == 1
        assert "soc_ctrl" in names

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
