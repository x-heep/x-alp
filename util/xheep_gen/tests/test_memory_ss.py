# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for memory_ss.memory_ss: bank placement, linker section inference,
overrides and validation."""

import pytest

from memory_ss.memory_ss import MemorySS
from memory_ss.linker_section import LinkerSection

KIB = 1024


def make_valid_memory() -> MemorySS:
    """Two 32kiB banks with code/data sections covering them."""
    mem = MemorySS()
    mem.add_ram_banks([32], "code")
    mem.add_ram_banks([32], "data")
    return mem


class TestBankPlacement:
    def test_continuous_banks_are_contiguous(self):
        mem = MemorySS()
        mem.add_ram_banks([32, 32, 64])
        banks = list(mem.iter_ram_banks())
        assert banks[0].start_address() == 0x0
        assert banks[0].end_address() == 32 * KIB
        assert banks[1].start_address() == 32 * KIB
        assert banks[2].start_address() == 64 * KIB
        assert banks[2].end_address() == 128 * KIB
        assert mem.ram_size_address() == 128 * KIB
        assert mem.ram_numbanks() == 3

    def test_map_indices_are_unique_and_consecutive(self):
        mem = MemorySS()
        mem.add_ram_banks([32, 32])
        mem.add_ram_banks([32])
        indices = [b.map_idx() for b in mem.iter_ram_banks()]
        assert indices == [1, 2, 3]

    def test_empty_bank_list_rejected(self):
        mem = MemorySS()
        with pytest.raises(ValueError):
            mem.add_ram_banks([])

    def test_section_for_banks_spans_all_banks(self):
        mem = MemorySS()
        mem.add_ram_banks([32, 32], "code")
        sections = list(mem.iter_linker_sections())
        assert len(sections) == 1
        assert sections[0].name == "code"
        assert sections[0].start == 0x0
        assert sections[0].end == 64 * KIB

    def test_duplicate_section_names_rejected(self):
        mem = MemorySS()
        mem.add_ram_banks([32], "code")
        with pytest.raises(ValueError, match="unique"):
            mem.add_ram_banks([32], "code")

    def test_duplicate_name_via_explicit_section_rejected(self):
        mem = MemorySS()
        mem.add_ram_banks([32], "code")
        with pytest.raises(ValueError, match="unique"):
            mem.add_linker_section(LinkerSection("code", 0x0, 0x1000))

    def test_iter_bank_numwords_deduplicates_sizes(self):
        mem = MemorySS()
        mem.add_ram_banks([32, 32, 64])
        # 32kiB -> 8192 words, 64kiB -> 16384 words, each yielded once.
        assert list(mem.iter_bank_numwords()) == [8192, 16384]


class TestInterleavedBanks:
    def test_il_group_geometry(self):
        mem = MemorySS()
        mem.add_ram_banks([32])
        mem.add_ram_banks_il(4, 32, "il_ram")
        assert mem.has_il_ram()
        assert mem.ram_numbanks_il() == 4
        assert mem.ram_numbanks() == 5

        group = next(mem.iter_il_groups())
        assert group.start == 32 * KIB
        assert group.size == 4 * 32 * KIB
        assert group.n == 4

    def test_il_banks_have_correct_offsets_and_levels(self):
        mem = MemorySS()
        mem.add_ram_banks_il(4, 32)
        banks = list(mem.iter_ram_banks())
        assert [b.il_offset() for b in banks] == [0, 1, 2, 3]
        # 4 banks -> 2 interleaving bits.
        assert all(b.il_level() == 2 for b in banks)

    def test_il_non_pow2_count_rejected(self):
        mem = MemorySS()
        with pytest.raises(ValueError, match="power of two"):
            mem.add_ram_banks_il(3, 32)

    def test_no_il_ram_by_default(self):
        mem = MemorySS()
        mem.add_ram_banks([32])
        assert not mem.has_il_ram()


class TestBuild:
    def test_build_infers_section_end_from_next_section(self):
        mem = MemorySS()
        mem.add_ram_banks([32, 32])
        mem.add_linker_section(LinkerSection("code", 0x0, None))
        mem.add_linker_section(LinkerSection("data", 0x4000, None))
        mem.build()
        sections = {s.name: s for s in mem.iter_linker_sections()}
        assert sections["code"].end == 0x4000
        # Last open-ended section ends at the end of the last ram bank.
        assert sections["data"].end == 64 * KIB

    def test_build_sorts_sections_by_start_address(self):
        mem = MemorySS()
        mem.add_ram_banks([32, 32])
        mem.add_linker_section(LinkerSection("data", 0x8000, None))
        mem.add_linker_section(LinkerSection("code", 0x0, 0x8000))
        mem.build()
        assert [s.name for s in mem.iter_linker_sections()] == ["code", "data"]

    def test_build_without_banks_cannot_infer_end(self):
        mem = MemorySS()
        mem.add_linker_section(LinkerSection("code", 0x0, None))
        with pytest.raises(RuntimeError):
            mem.build()


class TestOverrides:
    def test_override_ram_banks_replaces_config(self):
        mem = MemorySS()
        mem.add_ram_banks([64, 64])
        mem.override_ram_banks(4)
        assert mem.ram_numbanks() == 4
        assert all(b.size() == 32 * KIB for b in mem.iter_ram_banks())

    def test_add_after_override_is_ignored(self):
        mem = MemorySS()
        mem.override_ram_banks(2)
        mem.add_ram_banks([64, 64, 64])
        assert mem.ram_numbanks() == 2

    def test_override_il_applied_at_build(self):
        mem = MemorySS()
        mem.add_ram_banks([32, 32])
        mem.override_ram_banks_il(2)
        # The interleaved override drops the previous banks and is
        # deferred to build().
        assert not mem.has_il_ram()
        mem.build()
        assert mem.has_il_ram()
        assert mem.ram_numbanks_il() == 2
        assert mem.ram_numbanks() == 2

    def test_double_override_names_compat_il_group(self):
        mem = MemorySS()
        mem.override_ram_banks(2)
        mem.override_ram_banks_il(2)
        mem.build()
        # With more than one continuous bank the compatibility group
        # name is set automatically.
        group = next(mem.iter_il_groups())
        assert group.group_name == "data_interleaved"
        assert mem.ram_numbanks() == 4


class TestValidate:
    def test_valid_configuration_passes(self):
        mem = make_valid_memory()
        mem.build()
        mem.validate()

    def test_no_banks_rejected(self):
        mem = MemorySS()
        with pytest.raises(RuntimeError, match="number of banks"):
            mem.validate()

    def test_too_many_banks_rejected(self):
        mem = MemorySS()
        mem.add_ram_banks([32] * 17, "code")
        mem.add_linker_section(LinkerSection("data", 0x1000, 0x2000))
        with pytest.raises(RuntimeError, match="number of banks"):
            mem.validate()

    def test_missing_data_section_rejected(self):
        mem = MemorySS()
        mem.add_ram_banks([32, 32], "code")
        with pytest.raises(RuntimeError, match="code and data"):
            mem.validate()

    def test_first_section_must_be_code(self):
        mem = MemorySS()
        mem.add_ram_banks([32], "data")
        mem.add_ram_banks([32], "code")
        mem.build()  # sorts by start: data first
        with pytest.raises(RuntimeError, match="should be called code"):
            mem.validate()

    def test_overlapping_sections_rejected(self):
        mem = MemorySS()
        mem.add_ram_banks([32, 32])
        mem.add_linker_section(LinkerSection("code", 0x0, 0x9000))
        mem.add_linker_section(LinkerSection("data", 0x8000, 0x10000))
        mem.build()
        with pytest.raises(RuntimeError, match="overlap"):
            mem.validate()

    def test_section_beyond_ram_rejected(self):
        mem = MemorySS()
        mem.add_ram_banks([32])
        mem.add_linker_section(LinkerSection("code", 0x0, 0x4000))
        # data extends past the only 32kiB bank.
        mem.add_linker_section(LinkerSection("data", 0x4000, 0x20000))
        mem.build()
        with pytest.raises(RuntimeError, match="does not end in any ram bank"):
            mem.validate()

    def test_section_starting_outside_ram_rejected(self):
        mem = MemorySS()
        mem.add_ram_banks([32])
        mem.add_linker_section(LinkerSection("code", 0x0, 0x4000))
        mem.add_linker_section(LinkerSection("data", 0x100000, 0x101000))
        mem.build()
        with pytest.raises(RuntimeError, match="does not start in any ram bank"):
            mem.validate()


class TestStrRepresentation:
    def test_str_lists_banks_and_sections(self):
        mem = make_valid_memory()
        mem.add_ram_banks_il(2, 32, "il")
        text = str(mem)
        assert "RAM Banks (2)" in text
        assert "Interleaved RAM Banks (2)" in text
        assert "Linker Sections" in text


class TestArgumentValidation:
    def test_add_ram_banks_rejects_wrong_types(self):
        mem = MemorySS()
        with pytest.raises(TypeError, match="bank_sizes"):
            mem.add_ram_banks(32)
        with pytest.raises(TypeError, match="section_name"):
            mem.add_ram_banks([32], 42)
        with pytest.raises(ValueError, match="empty"):
            mem.add_ram_banks([])

    def test_add_ram_banks_il_rejects_wrong_types(self):
        mem = MemorySS()
        with pytest.raises(TypeError, match="num"):
            mem.add_ram_banks_il("2", 32)
        with pytest.raises(ValueError, match="power of two"):
            mem.add_ram_banks_il(3, 32)
        with pytest.raises(TypeError, match="group_name"):
            mem.add_ram_banks_il(2, 32, 42)


class TestLinkerSectionForBanks:
    def test_interleaved_requires_group_name(self):
        mem = MemorySS()
        mem.add_ram_banks_il(2, 32, "il")
        with pytest.raises(ValueError, match="il_group_name"):
            mem.add_linker_section_for_banks("section", interleaved=True)

    def test_interleaved_unknown_group_rejected(self):
        mem = MemorySS()
        mem.add_ram_banks_il(2, 32, "il")
        with pytest.raises(ValueError, match="not found"):
            mem.add_linker_section_for_banks(
                "section", interleaved=True, il_group_name="other"
            )

    def test_interleaved_section_spans_group(self):
        mem = MemorySS()
        mem.add_ram_banks([32])
        mem.add_ram_banks_il(2, 32, "il")
        mem.add_linker_section_for_banks("ilsec", interleaved=True, il_group_name="il")
        section = next(s for s in mem.iter_linker_sections() if s.name == "ilsec")
        assert section.size == 2 * 32 * 1024

    def test_duplicate_section_name_rejected(self):
        mem = MemorySS()
        mem.add_ram_banks([32], "code")
        with pytest.raises(ValueError, match="unique"):
            mem.add_ram_banks([32], "code")

    def test_add_linker_section_rejects_wrong_type(self):
        with pytest.raises(TypeError, match="LinkerSection"):
            MemorySS().add_linker_section("code")

    def test_add_linker_section_rejects_duplicate_name(self):
        mem = MemorySS()
        mem.add_linker_section(LinkerSection("code", 0x0, 0x4000))
        with pytest.raises(ValueError, match="unique"):
            mem.add_linker_section(LinkerSection("code", 0x4000, 0x8000))


class TestSectionNamingRules:
    def test_first_section_must_be_code(self):
        mem = MemorySS()
        mem.add_ram_banks([32, 32])
        # both names exist, but after sorting by start "data" comes first
        mem.add_linker_section(LinkerSection("data", 0x0, 0x4000))
        mem.add_linker_section(LinkerSection("code", 0x4000, 0x8000))
        mem.build()
        with pytest.raises(RuntimeError, match="should be called code"):
            mem.validate()

    def test_second_section_must_be_data(self):
        mem = MemorySS()
        mem.add_ram_banks([32, 32])
        mem.add_linker_section(LinkerSection("code", 0x0, 0x4000))
        mem.add_linker_section(LinkerSection("stuff", 0x4000, 0x8000))
        mem.add_linker_section(LinkerSection("data", 0x8000, 0xC000))
        mem.build()
        with pytest.raises(RuntimeError, match="should be called data"):
            mem.validate()
