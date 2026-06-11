# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for the CPU configuration classes."""

import pytest

from cpu.cpu import CPU
from cpu.cv32e20 import cv32e20
from cpu.cv32e40p import cv32e40p


class TestCPU:
    @pytest.mark.parametrize("name", ["cv32e20", "cv32e40p", "cv32e40px", "cv32e40x"])
    def test_known_cpus_accepted(self, name):
        assert CPU(name).get_name() == name

    def test_unknown_cpu_rejected(self):
        with pytest.raises(ValueError, match="Invalid CPU name"):
            CPU("riscy")

    def test_undefined_param(self):
        cpu = CPU("cv32e20")
        assert not cpu.is_defined("rv32e")
        assert cpu.get_param("rv32e") is None


class TestCv32e20:
    @pytest.mark.parametrize(
        "value,expected",
        [
            (True, True),
            (False, False),
            (1, True),
            (0, False),
            ("true", True),
            ("False", False),
            ("1", True),
            ("0", False),
        ],
    )
    def test_rv32e_value_coercion(self, value, expected):
        cpu = cv32e20(rv32e=value)
        assert cpu.get_param("rv32e") is expected

    def test_rv32e_invalid_string_rejected(self):
        with pytest.raises(ValueError, match="rv32e"):
            cv32e20(rv32e="yes")

    def test_rv32e_omitted_stays_undefined(self):
        assert not cv32e20().is_defined("rv32e")

    @pytest.mark.parametrize(
        "mode", ["RV32MNone", "RV32MSlow", "RV32MFast", "RV32MSingleCycle"]
    )
    def test_rv32m_valid_modes(self, mode):
        assert cv32e20(rv32m=mode).get_param("rv32m") == mode

    def test_rv32m_invalid_mode_rejected(self):
        with pytest.raises(ValueError, match="rv32m"):
            cv32e20(rv32m="RV32MTurbo")

    def test_sv_str_rendering(self):
        assert cv32e20(rv32e=True).get_sv_str("rv32e") == "1'b1"
        assert cv32e20(rv32e=False).get_sv_str("rv32e") == "1'b0"
        assert cv32e20(rv32m="RV32MFast").get_sv_str("rv32m") == "RV32MFast"
        # Undefined parameters render as empty string for the templates.
        assert cv32e20().get_sv_str("rv32e") == ""


class TestCv32e40p:
    def test_name(self):
        assert cv32e40p().get_name() == "cv32e40p"


class TestCv32e20EdgeCases:
    def test_rv32e_invalid_value_rejected(self):
        with pytest.raises(ValueError, match="rv32e"):
            cv32e20(rv32e=2)

    def test_sv_str_falls_back_to_str(self):
        cpu = cv32e20()
        cpu.params["custom"] = 7
        assert cpu.get_sv_str("custom") == "7"
