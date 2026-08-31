# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for memory_ss.linker_section: construction and sanity checks."""

import pytest

from memory_ss.linker_section import LinkerSection
from memory_ss.linker_subsection import LinkerSubsection


class TestLinkerSection:
    def test_basic_construction(self):
        sec = LinkerSection("code", 0x0, 0x8000)
        assert sec.name == "code"
        assert sec.start == 0x0
        assert sec.end == 0x8000
        assert sec.size == 0x8000

    def test_open_ended_section_has_no_size(self):
        # end=None means "infer during build"; until then size is unknown.
        sec = LinkerSection("data", 0x8000, None)
        assert sec.end is None
        assert sec.size is None

    def test_by_size_factory(self):
        sec = LinkerSection.by_size("data", 0x8000, 0x4000)
        assert sec.start == 0x8000
        assert sec.end == 0xC000
        assert sec.size == 0x4000

    def test_default_subsection_uses_section_name(self):
        sec = LinkerSection("myram", 0x0, 0x1000)
        assert len(sec.subsections) == 1
        assert isinstance(sec.subsections[0], LinkerSubsection)

    def test_empty_name_rejected(self):
        with pytest.raises(ValueError):
            LinkerSection("", 0x0, 0x1000)

    def test_negative_start_rejected(self):
        with pytest.raises(ValueError):
            LinkerSection("code", -4, 0x1000)

    def test_end_before_start_rejected(self):
        with pytest.raises(ValueError):
            LinkerSection("code", 0x1000, 0x800)

    def test_end_equal_start_rejected(self):
        with pytest.raises(ValueError):
            LinkerSection("code", 0x1000, 0x1000)

    @pytest.mark.parametrize(
        "name,start,end",
        [
            (42, 0x0, 0x1000),
            ("code", "0", 0x1000),
            ("code", 0x0, "0x1000"),
        ],
    )
    def test_type_errors(self, name, start, end):
        with pytest.raises(TypeError):
            LinkerSection(name, start, end)

    def test_check_catches_mutation_after_construction(self):
        # check() is re-run by MemorySS.validate(); it must catch fields
        # that were mutated into an invalid state after construction.
        sec = LinkerSection("code", 0x0, 0x1000)
        sec.end = 0x0
        with pytest.raises(ValueError):
            sec.check()


class TestLinkerSectionTypeChecks:
    def test_invalid_subsections_rejected(self):
        with pytest.raises(TypeError, match="subsections"):
            LinkerSection("code", 0x0, 0x1000, subsections="bad")
        with pytest.raises(TypeError, match="only LinkerSubsection"):
            LinkerSection("code", 0x0, 0x1000, subsections=["bad"])

    def test_by_size_type_errors(self):
        with pytest.raises(TypeError, match="name"):
            LinkerSection.by_size(42, 0x0, 0x1000)
        with pytest.raises(TypeError, match="start"):
            LinkerSection.by_size("code", "0", 0x1000)
        with pytest.raises(TypeError, match="size"):
            LinkerSection.by_size("code", 0x0, "0x1000")


class TestLinkerSubsection:
    def test_defaults(self):
        sub = LinkerSubsection("code")
        assert sub.subsections_names == ["code"]

    def test_type_errors(self):
        with pytest.raises(TypeError, match="name"):
            LinkerSubsection(42)
        with pytest.raises(TypeError, match="only strings"):
            LinkerSubsection("code", subsections_names=[42])
        with pytest.raises(TypeError, match="provide_start"):
            LinkerSubsection("code", provide_start="yes")
        with pytest.raises(TypeError, match="provide_end"):
            LinkerSubsection("code", provide_end="yes")

    def test_check_catches_non_list_mutation(self):
        sub = LinkerSubsection("code")
        sub.subsections_names = "bad"
        with pytest.raises(TypeError, match="subsections_names"):
            sub.check()

    def test_value_errors(self):
        with pytest.raises(ValueError, match="empty"):
            LinkerSubsection("code", subsections_names=[])
        with pytest.raises(ValueError, match="empty"):
            LinkerSubsection("code", subsections_names=[""])
