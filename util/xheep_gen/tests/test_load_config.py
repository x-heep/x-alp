# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for load_config: hjson parsing helpers and end-to-end config
loading."""

import hjson
import pytest

from bus_type import BusType
from load_config import (
    load_cfg_file,
    load_cfg_hjson,
    ram_list,
    to_int,
)

KIB = 1024

MINIMAL_CFG = """
{
    bus_type: onetoM
    cpu_type: cv32e20
    ram_banks: {
        code_and_data: {
            num: 2
            sizes: [32]
        }
    }
    linker_sections: [
        {
            name: code
            start: 0
            size: 0x8000
        }
        {
            name: data
            start: 0x8000
        }
    ]
}
"""


class TestToInt:
    @pytest.mark.parametrize(
        "value,expected",
        [
            (42, 42),
            ("42", 42),
            ("0x10", 16),
            ("0X10", 16),
            ("0o10", 8),
            ("0xABCD", 0xABCD),
            ("0", 0),
        ],
    )
    def test_accepted_formats(self, value, expected):
        assert to_int(value) == expected

    def test_unsupported_type_returns_none(self):
        assert to_int(3.14) is None
        assert to_int(None) is None
        assert to_int([1]) is None

    @pytest.mark.xfail(
        reason="bug: prefix check does input[0:2].upper() == '0b', which can "
        "never match since upper() yields '0B'",
        strict=True,
    )
    def test_binary_prefix(self):
        assert to_int("0b101") == 5


class TestRamList:
    def parse(self, src):
        return hjson.loads(src, object_pairs_hook=hjson.OrderedDict)

    def test_plain_int(self):
        sizes = []
        ram_list(sizes, 32)
        assert sizes == [32]

    def test_nested_lists_are_flattened(self):
        sizes = []
        ram_list(sizes, [32, [64, 32]])
        assert sizes == [32, 64, 32]

    def test_dict_with_num_repeats_sizes(self):
        entry = self.parse("{ num: 2, sizes: [16, 32] }")
        sizes = []
        ram_list(sizes, entry)
        assert sizes == [16, 32, 16, 32]

    def test_dict_without_num_defaults_to_one(self):
        entry = self.parse("{ sizes: 64 }")
        sizes = []
        ram_list(sizes, entry)
        assert sizes == [64]

    def test_dict_without_sizes_rejected(self):
        entry = self.parse("{ num: 2 }")
        with pytest.raises(RuntimeError, match="sizes"):
            ram_list([], entry)

    def test_non_int_num_rejected(self):
        entry = self.parse('{ num: "two", sizes: 32 }')
        with pytest.raises(RuntimeError, match="num"):
            ram_list([], entry)

    def test_invalid_entry_type_rejected(self):
        with pytest.raises(RuntimeError):
            ram_list([], "32")

    def test_target_must_be_list(self):
        with pytest.raises(TypeError):
            ram_list("not-a-list", 32)


class TestLoadCfgHjson:
    def test_minimal_config_builds_system(self):
        system = load_cfg_hjson(MINIMAL_CFG)
        assert system.bus_type() == BusType.onetoM
        assert system.cpu().get_name() == "cv32e20"

        mem = system.memory_ss()
        assert mem.ram_numbanks() == 2
        assert mem.ram_size_address() == 64 * KIB

        sections = {s.name: s for s in mem.iter_linker_sections()}
        assert sections["code"].start == 0x0
        assert sections["code"].end == 0x8000
        assert sections["data"].start == 0x8000
        # data has no size/end: inferred later by build().
        assert sections["data"].end is None

    def test_system_validates_after_build(self):
        system = load_cfg_hjson(MINIMAL_CFG)
        system.build()
        system.memory_ss().validate()

    def test_interleaved_ram_config(self):
        cfg = """
        {
            bus_type: NtoM
            cpu_type: cv32e20
            ram_banks: {
                code_and_data: {
                    sizes: [32, 32]
                }
                il_ram: {
                    type: interleaved
                    num: 4
                    size: 32
                }
            }
        }
        """
        system = load_cfg_hjson(cfg)
        mem = system.memory_ss()
        assert mem.has_il_ram()
        assert mem.ram_numbanks_il() == 4
        assert mem.ram_numbanks() == 6

    def test_auto_section_from_ram_bank_name(self):
        cfg = """
        {
            bus_type: onetoM
            cpu_type: cv32e20
            ram_banks: {
                code: {
                    auto_section: auto
                    sizes: [32]
                }
                data: {
                    auto_section: auto
                    sizes: [32]
                }
            }
        }
        """
        system = load_cfg_hjson(cfg)
        names = [s.name for s in system.memory_ss().iter_linker_sections()]
        assert names == ["code", "data"]

    @pytest.mark.parametrize("missing_key", ["ram_banks", "bus_type", "cpu_type"])
    def test_missing_mandatory_key_rejected(self, missing_key):
        cfg = hjson.loads(MINIMAL_CFG, object_pairs_hook=hjson.OrderedDict)
        del cfg[missing_key]
        with pytest.raises(RuntimeError):
            load_cfg_hjson(hjson.dumps(cfg))

    def test_invalid_bus_type_rejected(self):
        cfg = MINIMAL_CFG.replace("onetoM", "badbus")
        with pytest.raises(ValueError):
            load_cfg_hjson(cfg)

    def test_invalid_ram_type_rejected(self):
        cfg = """
        {
            bus_type: onetoM
            cpu_type: cv32e20
            ram_banks: {
                ram: {
                    type: sparse
                    sizes: [32]
                }
            }
        }
        """
        with pytest.raises(RuntimeError, match="continuous or interleaved"):
            load_cfg_hjson(cfg)

    def test_section_with_size_and_end_rejected(self):
        cfg = """
        {
            bus_type: onetoM
            cpu_type: cv32e20
            ram_banks: {
                ram: {
                    sizes: [32]
                }
            }
            linker_sections: [
                {
                    name: code
                    start: 0
                    size: 0x1000
                    end: 0x2000
                }
            ]
        }
        """
        with pytest.raises(RuntimeError, match="end or size"):
            load_cfg_hjson(cfg)

    def test_section_with_non_positive_size_rejected(self):
        cfg = """
        {
            bus_type: onetoM
            cpu_type: cv32e20
            ram_banks: {
                ram: {
                    sizes: [32]
                }
            }
            linker_sections: [
                {
                    name: code
                    start: 0
                    size: 0
                }
            ]
        }
        """
        with pytest.raises(RuntimeError, match="strictly positive"):
            load_cfg_hjson(cfg)

    def test_section_end_before_start_rejected(self):
        cfg = """
        {
            bus_type: onetoM
            cpu_type: cv32e20
            ram_banks: {
                ram: {
                    sizes: [32]
                }
            }
            linker_sections: [
                {
                    name: code
                    start: 0x2000
                    end: 0x1000
                }
            ]
        }
        """
        with pytest.raises(RuntimeError, match="end after their start"):
            load_cfg_hjson(cfg)

    def test_hex_string_addresses_are_parsed(self):
        cfg = """
        {
            bus_type: onetoM
            cpu_type: cv32e20
            ram_banks: {
                ram: {
                    sizes: [32]
                }
            }
            linker_sections: [
                {
                    name: code
                    start: "0x100"
                    size: "0x100"
                }
            ]
        }
        """
        system = load_cfg_hjson(cfg)
        sec = next(system.memory_ss().iter_linker_sections())
        assert sec.start == 0x100
        assert sec.end == 0x200


class TestCpuConfig:
    def test_cpu_features_are_applied(self):
        cfg = """
        {
            bus_type: onetoM
            cpu_type: cv32e20
            cpu_features: {
                cve2_rv32e: false
                cve2_rv32m: RV32MFast
            }
            ram_banks: {
                ram: {
                    sizes: [32]
                }
            }
        }
        """
        system = load_cfg_hjson(cfg)
        cpu = system.cpu()
        assert cpu.get_param("rv32e") is False
        assert cpu.get_param("rv32m") == "RV32MFast"

    def test_cv_x_if_enabled_for_supported_cpu(self):
        cfg = """
        {
            bus_type: onetoM
            cpu_type: cv32e20
            cpu_features: {
                cv_x_if: true
            }
            ram_banks: {
                ram: {
                    sizes: [32]
                }
            }
        }
        """
        system = load_cfg_hjson(cfg)
        assert system.xif() is not None

    def test_cv_x_if_not_enabled_for_cv32e40p(self):
        cfg = """
        {
            bus_type: onetoM
            cpu_type: cv32e40p
            cpu_features: {
                cv_x_if: true
            }
            ram_banks: {
                ram: {
                    sizes: [32]
                }
            }
        }
        """
        system = load_cfg_hjson(cfg)
        assert system.xif() is None

    def test_unknown_cpu_type_rejected(self):
        cfg = MINIMAL_CFG.replace("cv32e20", "z80")
        with pytest.raises(ValueError, match="Invalid CPU name"):
            load_cfg_hjson(cfg)


class TestLoadCfgFile:
    def test_hjson_file(self, tmp_path):
        f = tmp_path / "cfg.hjson"
        f.write_text(MINIMAL_CFG)
        system = load_cfg_file(f)
        assert system.cpu().get_name() == "cv32e20"

    def test_python_file(self, tmp_path):
        f = tmp_path / "cfg.py"
        f.write_text(
            "from xheep import XHeep, BusType\n"
            "def config():\n"
            "    return XHeep(BusType.NtoM)\n"
        )
        # The config module resolves imports through the repo root already
        # present on sys.path (set by conftest).
        system = load_cfg_file(f)
        assert system.bus_type() == BusType.NtoM

    def test_unsupported_extension_rejected(self, tmp_path):
        f = tmp_path / "cfg.json"
        f.write_text("{}")
        with pytest.raises(RuntimeError, match="unsupported file extension"):
            load_cfg_file(f)

    def test_path_type_checked(self):
        with pytest.raises(TypeError):
            load_cfg_file("config.hjson")


class TestLoadRamConfigErrors:
    def parse(self, src):
        return hjson.loads(src, object_pairs_hook=hjson.OrderedDict)

    def make(self):
        from memory_ss.memory_ss import MemorySS

        return MemorySS()

    def test_wrong_argument_types(self):
        from load_config import load_ram_config

        with pytest.raises(TypeError, match="MemorySS"):
            load_ram_config("memory", self.parse("{}"))
        with pytest.raises(TypeError, match="OrderedDict"):
            load_ram_config(self.make(), "config")

    def test_entry_must_be_dict(self):
        from load_config import load_ram_config

        with pytest.raises(RuntimeError, match="dictionaries"):
            load_ram_config(self.make(), self.parse("{ code: 32 }"))

    def test_ram_type_must_be_string(self):
        from load_config import load_ram_config

        cfg = self.parse('{"code": {"type": 1, "sizes": 32}}')
        with pytest.raises(TypeError, match="string"):
            load_ram_config(self.make(), cfg)

    def test_unknown_ram_type_rejected(self):
        from load_config import load_ram_config

        cfg = self.parse('{"code": {"type": "scattered", "sizes": 32}}')
        with pytest.raises(RuntimeError, match="continuous or interleaved"):
            load_ram_config(self.make(), cfg)

    @pytest.mark.parametrize("missing", ["num", "size"])
    def test_interleaved_requires_num_and_size(self, missing):
        from load_config import load_ram_config

        cfg = self.parse('{"il": {"type": "interleaved", "num": 2, "size": 32}}')
        del cfg["il"][missing]
        with pytest.raises(RuntimeError, match=missing):
            load_ram_config(self.make(), cfg)

    def test_interleaved_auto_section(self):
        from load_config import load_ram_config

        cfg = self.parse(
            '{"il": {"type": "interleaved", "auto_section": "auto", "num": 2, "size": 32}}'
        )
        mem = self.make()
        load_ram_config(mem, cfg)
        assert any(s.name == "il" for s in mem.iter_linker_sections())


class TestLoadLinkerConfigErrors:
    def parse(self, src):
        return hjson.loads(src, object_pairs_hook=hjson.OrderedDict)

    def load(self, src):
        from load_config import load_linker_config
        from memory_ss.memory_ss import MemorySS

        load_linker_config(MemorySS(), self.parse(src))

    def test_config_must_be_list(self):
        with pytest.raises(TypeError, match="list"):
            self.load("{}")

    def test_sections_must_be_dicts(self):
        with pytest.raises(TypeError, match="Dictionaries"):
            self.load('["section"]')

    @pytest.mark.parametrize(
        "src,error,message",
        [
            ('[{"start": 0}]', RuntimeError, "names"),
            ('[{"name": "code"}]', RuntimeError, "start"),
            ('[{"name": 42, "start": 0}]', TypeError, "strings"),
            ('[{"name": "", "start": 0}]', RuntimeError, "empty"),
            # floats are not handled by to_int and yield None
            ('[{"name": "code", "start": 1.5}]', TypeError, "integer"),
            (
                '[{"name": "code", "start": 0, "size": 256, "end": 256}]',
                RuntimeError,
                "end or size",
            ),
            ('[{"name": "code", "start": 0, "size": 1.5}]', RuntimeError, "integer"),
            ('[{"name": "code", "start": 0, "size": -1}]', RuntimeError, "positive"),
            ('[{"name": "code", "start": 0, "end": 1.5}]', RuntimeError, "integer"),
            ('[{"name": "code", "start": 256, "end": 256}]', RuntimeError, "after"),
        ],
    )
    def test_invalid_sections_rejected(self, src, error, message):
        with pytest.raises(error, match=message):
            self.load(src)


class TestLoadCpuConfig:
    def test_wrong_argument_types(self):
        from load_config import load_cpu_config
        from bus_type import BusType
        from xheep import XHeep

        system = XHeep(BusType.onetoM)
        with pytest.raises(TypeError, match="string"):
            load_cpu_config(system, 42, hjson.OrderedDict())
        with pytest.raises(TypeError, match="OrderedDict"):
            load_cpu_config(system, "cv32e20", {})

    @pytest.mark.parametrize("cpu_type", ["cv32e40p", "cv32e40px", "cv32e40x"])
    def test_cpu_variants(self, cpu_type):
        system = load_cfg_hjson(MINIMAL_CFG.replace("cv32e20", cpu_type))
        assert system.cpu().get_name() == cpu_type

    def test_cv_x_if_enabled_for_supported_cpu(self):
        cfg = MINIMAL_CFG.replace(
            "cpu_type: cv32e20",
            "cpu_type: cv32e20\n    cpu_features: {\n        cv_x_if: yes\n    }",
        )
        system = load_cfg_hjson(cfg)
        assert system.xif() is not None
        assert system.xif().get_param("x_num_rs") is not None


class TestLoadPadCfgErrors:
    def test_path_must_be_purepath(self):
        from load_config import load_pad_cfg

        with pytest.raises(TypeError, match="PurePath"):
            load_pad_cfg("pads.py", None)

    def test_unsupported_extension_rejected(self):
        from load_config import load_pad_cfg
        from pathlib import PurePath

        with pytest.raises(RuntimeError, match="unsupported"):
            load_pad_cfg(PurePath("pads.hjson"), None)
