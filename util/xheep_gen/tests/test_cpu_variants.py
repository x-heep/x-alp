# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for the cv32e40p, cv32e40px and cv32e40x CPU variants: parameter
coercion, dependency rules and SystemVerilog rendering."""

import pytest

from cpu.cv32e40p import cv32e40p
from cpu.cv32e40px import cv32e40px
from cpu.cv32e40x import cv32e40x


class TestCv32e40pFpu:
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
    def test_value_coercion(self, value, expected):
        assert cv32e40p(fpu=value).get_param("fpu") is expected

    def test_invalid_string_rejected(self):
        with pytest.raises(ValueError, match="fpu"):
            cv32e40p(fpu="maybe")

    def test_invalid_value_rejected(self):
        with pytest.raises(ValueError, match="fpu"):
            cv32e40p(fpu=2)

    def test_omitted_stays_undefined(self):
        assert not cv32e40p().is_defined("fpu")


class TestCv32e40pFpuLatencies:
    @pytest.mark.parametrize("param", ["fpu_addmul_lat", "fpu_others_lat"])
    def test_requires_fpu(self, param):
        with pytest.raises(ValueError, match="requires fpu"):
            cv32e40p(**{param: 1})
        with pytest.raises(ValueError, match="requires fpu"):
            cv32e40p(fpu=0, **{param: 1})

    @pytest.mark.parametrize("param", ["fpu_addmul_lat", "fpu_others_lat"])
    def test_string_coercion(self, param):
        cpu = cv32e40p(fpu=True, **{param: "2"})
        assert cpu.get_param(param) == 2

    @pytest.mark.parametrize("param", ["fpu_addmul_lat", "fpu_others_lat"])
    def test_non_numeric_string_rejected(self, param):
        with pytest.raises(ValueError, match="must be a number"):
            cv32e40p(fpu=True, **{param: "abc"})

    @pytest.mark.parametrize("param", ["fpu_addmul_lat", "fpu_others_lat"])
    def test_negative_rejected(self, param):
        with pytest.raises(ValueError, match="positive"):
            cv32e40p(fpu=True, **{param: -1})


class TestCv32e40pZfinx:
    def test_requires_fpu(self):
        with pytest.raises(ValueError, match="requires fpu"):
            cv32e40p(zfinx=True)

    @pytest.mark.parametrize(
        "value,expected", [(True, True), ("0", False), ("true", True)]
    )
    def test_value_coercion(self, value, expected):
        assert cv32e40p(fpu=True, zfinx=value).get_param("zfinx") is expected

    def test_invalid_string_rejected(self):
        with pytest.raises(ValueError, match="zfinx"):
            cv32e40p(fpu=True, zfinx="maybe")

    def test_invalid_value_rejected(self):
        with pytest.raises(ValueError, match="zfinx"):
            cv32e40p(fpu=True, zfinx=3)


class TestCv32e40pCorevPulp:
    @pytest.mark.parametrize(
        "value,expected", [(True, True), (0, False), ("1", True), ("false", False)]
    )
    def test_value_coercion(self, value, expected):
        assert cv32e40p(corev_pulp=value).get_param("corev_pulp") is expected

    def test_invalid_string_rejected(self):
        with pytest.raises(ValueError, match="corev_pulp"):
            cv32e40p(corev_pulp="maybe")

    def test_invalid_value_rejected(self):
        with pytest.raises(ValueError, match="corev_pulp"):
            cv32e40p(corev_pulp=5)


class TestCv32e40pMhpmcounters:
    def test_int_and_string_accepted(self):
        assert cv32e40p(num_mhpmcounters=4).get_param("num_mhpmcounters") == 4
        assert cv32e40p(num_mhpmcounters="8").get_param("num_mhpmcounters") == 8

    def test_non_numeric_string_rejected(self):
        with pytest.raises(ValueError, match="must be a number"):
            cv32e40p(num_mhpmcounters="many")

    def test_negative_rejected(self):
        with pytest.raises(ValueError, match="positive"):
            cv32e40p(num_mhpmcounters=-1)


class TestCv32e40pSvStr:
    def test_undefined_param_renders_empty(self):
        assert cv32e40p().get_sv_str("fpu") == ""

    def test_boolean_params_render_as_bits(self):
        cpu = cv32e40p(fpu=True, zfinx=False, corev_pulp=True)
        assert cpu.get_sv_str("fpu") == "1"
        assert cpu.get_sv_str("zfinx") == "0"
        assert cpu.get_sv_str("corev_pulp") == "1"

    def test_numeric_param_renders_as_decimal(self):
        assert cv32e40p(num_mhpmcounters=4).get_sv_str("num_mhpmcounters") == "4"


class TestCv32e40px:
    def test_name(self):
        assert cv32e40px().get_name() == "cv32e40px"

    def test_parameters_forwarded_to_parent(self):
        cpu = cv32e40px(fpu=True, zfinx=True)
        assert cpu.get_param("fpu") is True
        assert cpu.get_param("zfinx") is True

    def test_sv_str_rendering(self):
        cpu = cv32e40px(fpu=True)
        assert cpu.get_sv_str("fpu") == "1"
        assert cpu.get_sv_str("zfinx") == ""


class TestCv32e40x:
    def test_name(self):
        assert cv32e40x().get_name() == "cv32e40x"

    def test_mhpmcounters_int_and_string(self):
        assert cv32e40x(num_mhpmcounters=2).get_param("num_mhpmcounters") == 2
        assert cv32e40x(num_mhpmcounters="3").get_param("num_mhpmcounters") == 3

    def test_mhpmcounters_non_numeric_rejected(self):
        with pytest.raises(ValueError, match="must be a number"):
            cv32e40x(num_mhpmcounters="many")

    def test_mhpmcounters_negative_rejected(self):
        with pytest.raises(ValueError, match="positive"):
            cv32e40x(num_mhpmcounters=-2)

    def test_sv_str_rendering(self):
        assert cv32e40x().get_sv_str("num_mhpmcounters") == ""
        assert cv32e40x(num_mhpmcounters=2).get_sv_str("num_mhpmcounters") == "2"
