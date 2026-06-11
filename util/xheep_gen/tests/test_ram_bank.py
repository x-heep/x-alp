# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for memory_ss.ram_bank: address computation and parameter checking."""

import pytest

from memory_ss.ram_bank import Bank, is_pow2


class TestIsPow2:
    @pytest.mark.parametrize("n", [1, 2, 4, 8, 1024, 2**20])
    def test_powers_of_two(self, n):
        assert is_pow2(n)

    @pytest.mark.parametrize("n", [0, -1, -2, 3, 6, 12, 1023])
    def test_non_powers_of_two(self, n):
        assert not is_pow2(n)


class TestBank:
    def test_end_address_simple(self):
        bank = Bank(32, 0x0000, 1)
        assert bank.start_address() == 0x0000
        assert bank.end_address() == 32 * 1024
        assert bank.size() == 32 * 1024

    def test_end_address_with_offset(self):
        bank = Bank(64, 0x10000, 3)
        assert bank.end_address() == 0x10000 + 64 * 1024

    def test_interleaved_end_address_covers_whole_group(self):
        # In interleaved mode every bank of the group reports the end
        # address of the whole group: size * 2**il_level.
        bank = Bank(32, 0x0000, 1, il_level=2, il_offset=0)
        assert bank.end_address() == 32 * 1024 * 4

    def test_non_pow2_size_rejected(self):
        with pytest.raises(ValueError, match="power of two"):
            Bank(48, 0x0000, 1)

    def test_zero_size_rejected(self):
        with pytest.raises(ValueError, match="power of two"):
            Bank(0, 0x0000, 1)

    def test_unaligned_start_address_rejected(self):
        with pytest.raises(ValueError, match="aligned"):
            Bank(32, 0x0002, 1)

    def test_il_offset_too_big_for_il_level(self):
        # il_level=1 allows offsets 0 and 1 only.
        with pytest.raises(ValueError, match="il_offset"):
            Bank(32, 0x0000, 1, il_level=1, il_offset=2)

    def test_il_offset_at_limit_is_accepted(self):
        bank = Bank(32, 0x0000, 1, il_level=1, il_offset=1)
        assert bank.il_offset() == 1

    @pytest.mark.parametrize(
        "kwargs",
        [
            {"size_k": "32", "start_address": 0, "map_idx": 1},
            {"size_k": 32, "start_address": "0", "map_idx": 1},
            {"size_k": 32, "start_address": 0, "map_idx": "1"},
            {"size_k": 32, "start_address": 0, "map_idx": 1, "il_level": "0"},
            {"size_k": 32, "start_address": 0, "map_idx": 1, "il_offset": "0"},
        ],
    )
    def test_type_errors(self, kwargs):
        with pytest.raises(TypeError):
            Bank(**kwargs)
