# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for mcu_gen: hjson helpers, template rendering and the end-to-end
configuration generation entry points."""

import argparse
import sys

import pytest

from mcu_gen import generate_xheep, main, string2int, write_template

PADS_CFG = """
from pads.dimension import Dimension
from pads.floorplan import FloorplanDimensions, Side
from pads.pad_ring import PadRing
from pads.pin import Input


def config(xheep):
    pin = Input("clk")
    floorplan = FloorplanDimensions(
        Dimension(3000, 3000),
        {side: 5 for side in Side},
        {side: 10 for side in Side},
        {side: 20 for side in Side},
    )
    return PadRing(floorplan, {Side.LEFT: [[pin]]}, [pin], {})
"""

PYTHON_CFG = """
from bus_type import BusType
from cpu.cv32e20 import cv32e20
from memory_ss.memory_ss import MemorySS
from xheep import XHeep


def config():
    system = XHeep(BusType.NtoM)
    mem = MemorySS()
    mem.add_ram_banks([32], "code")
    mem.add_ram_banks([32], "data")
    system.set_memory_ss(mem)
    system.set_cpu(cv32e20())
    return system
"""

BASE_CFG = """
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
    debug: {
        address: "0x10000000,"
        length:  "0x00100000,"
    }
    ext_slaves: {
        address: "0xF0000000,"
        length:  "0x01000000,"
    }
    flash_mem: {
        address: "0x40000000,"
        length:  "0x01000000,"
    }
    linker_script: {
        stack_size: "0x800,"
        heap_size:  "0x800,"
    }
    interrupts: {
        number: 64
        list: {
            irq_uart: "1"
            irq_gpio: "2"
        }
    }
}
"""


def write_cfg_files(tmp_path, cfg_text=BASE_CFG):
    cfg = tmp_path / "mcu_cfg.hjson"
    cfg.write_text(cfg_text)
    pads = tmp_path / "pads.py"
    pads.write_text(PADS_CFG)
    return cfg, pads


def make_args(tmp_path, cfg_text=BASE_CFG, **overrides):
    cfg, pads = write_cfg_files(tmp_path, cfg_text)
    defaults = dict(
        config=str(cfg),
        python_config="",
        pads_cfg=str(pads),
        cpu="",
        bus="",
        memorybanks="",
        memorybanks_il="",
        verbose=False,
        outfile=None,
        outtpl="",
        externaltpl="",
    )
    defaults.update(overrides)
    return argparse.Namespace(**defaults)


class TestString2Int:
    def test_strips_prefix_and_trailing_comma(self):
        assert string2int("0x10000000,") == "10000000"
        assert string2int("0x800") == "800"


class TestWriteTemplate:
    def test_renders_kwargs(self, tmp_path):
        tpl = tmp_path / "out.txt.tpl"
        tpl.write_text("hello ${name}")
        out = tmp_path / "result.txt"
        write_template(tpl, out, name="world")
        assert out.read_text() == "hello world"

    def test_default_outfile_strips_suffix(self, tmp_path):
        tpl = tmp_path / "out.txt.tpl"
        tpl.write_text("value ${name}   ")
        write_template(tpl, None, name="x")
        # trailing whitespace is trimmed too
        assert (tmp_path / "out.txt").read_text() == "value x"

    def test_missing_template_rejected(self, tmp_path):
        with pytest.raises(FileNotFoundError, match="not found"):
            write_template(tmp_path / "missing.tpl", None)

    def test_no_template_rejected(self):
        with pytest.raises(FileNotFoundError, match="not provided"):
            write_template(None, None)


class TestGenerateXheep:
    def test_happy_path(self, tmp_path):
        kwargs = generate_xheep(make_args(tmp_path))
        assert kwargs["debug_start_address"] == "10000000"
        assert kwargs["debug_size_address"] == "00100000"
        assert kwargs["has_spi_slave"] == 0
        assert kwargs["stack_size"] == "800"
        assert kwargs["heap_size"] == "800"
        assert kwargs["plic_used_n_interrupts"] == 2
        assert kwargs["plit_n_interrupts"] == 64
        assert "EXT_INTR_0" in kwargs["interrupts"]
        assert "irq_uart" in kwargs["interrupts"]
        # serial_link is absent from the config, defaults apply
        assert kwargs["serial_link_start_address"] == 0x50000000
        assert kwargs["serial_link_size_address"] == 0x01000000

        xheep = kwargs["xheep"]
        assert xheep.cpu().get_name() == "cv32e20"
        assert xheep.get_padring() is not None

    def test_verbose_flag(self, tmp_path):
        generate_xheep(make_args(tmp_path, verbose=True))

    def test_spi_slave_and_serial_link(self, tmp_path):
        cfg = BASE_CFG.replace(
            "debug: {",
            "serial_link: {\n"
            '        address: "0x60000000,"\n'
            '        length: "0x02000000,"\n'
            "    }\n"
            "    debug: {\n"
            "        has_spi_slave: yes",
        )
        kwargs = generate_xheep(make_args(tmp_path, cfg_text=cfg))
        assert kwargs["has_spi_slave"] == 1
        assert kwargs["serial_link_start_address"] == "60000000"
        assert kwargs["serial_link_size_address"] == "02000000"

    def test_low_debug_address_exits(self, tmp_path):
        cfg = BASE_CFG.replace('address: "0x10000000,"', 'address: "0x8000,"')
        with pytest.raises(SystemExit, match="debug start address"):
            generate_xheep(make_args(tmp_path, cfg_text=cfg))

    def test_stack_and_heap_must_fit_in_ram(self, tmp_path):
        cfg = BASE_CFG.replace('stack_size: "0x800,"', 'stack_size: "0x100000,"')
        with pytest.raises(SystemExit, match="stack and heap"):
            generate_xheep(make_args(tmp_path, cfg_text=cfg))

    def test_command_line_overrides(self, tmp_path):
        from bus_type import BusType

        kwargs = generate_xheep(
            make_args(tmp_path, bus="NtoM", cpu="cv32e40p", memorybanks="4")
        )
        xheep = kwargs["xheep"]
        assert xheep.bus_type() == BusType.NtoM
        assert xheep.cpu().get_name() == "cv32e40p"
        assert xheep.memory_ss().ram_numbanks() == 4

    def test_memorybanks_il_override(self, tmp_path):
        kwargs = generate_xheep(make_args(tmp_path, bus="NtoM", memorybanks_il="2"))
        assert kwargs["xheep"].memory_ss().ram_numbanks_il() == 2

    def test_python_config_takes_precedence(self, tmp_path):
        from bus_type import BusType

        py_cfg = tmp_path / "cfg.py"
        py_cfg.write_text(PYTHON_CFG)
        kwargs = generate_xheep(make_args(tmp_path, python_config=str(py_cfg)))
        # The python config selects the NtoM bus while the hjson says onetoM.
        assert kwargs["xheep"].bus_type() == BusType.NtoM


class TestMain:
    def run_main(self, monkeypatch, tmp_path, *extra):
        cfg, pads = write_cfg_files(tmp_path)
        argv = [
            "mcugen",
            "--config",
            str(cfg),
            "--pads_cfg",
            str(pads),
            *extra,
        ]
        monkeypatch.setattr(sys, "argv", argv)
        main()

    def test_single_template(self, monkeypatch, tmp_path):
        tpl = tmp_path / "single.txt.tpl"
        tpl.write_text("cpu ${xheep.cpu().get_name()}")
        out = tmp_path / "single.txt"
        self.run_main(
            monkeypatch, tmp_path, "--outtpl", str(tpl), "--outfile", str(out)
        )
        assert out.read_text() == "cpu cv32e20"

    def test_multiple_templates(self, monkeypatch, tmp_path):
        tpl1 = tmp_path / "a.txt.tpl"
        tpl1.write_text("stack ${stack_size}")
        tpl2 = tmp_path / "b.txt"  # no .tpl suffix: rendered onto itself
        tpl2.write_text("heap ${heap_size}")
        self.run_main(monkeypatch, tmp_path, "--outtpl", f"{tpl1},{tpl2}")
        assert (tmp_path / "a.txt").read_text() == "stack 800"
        assert tpl2.read_text() == "heap 800"

    def test_external_templates(self, monkeypatch, tmp_path):
        tpl1 = tmp_path / "a.txt.tpl"
        tpl1.write_text("stack ${stack_size}")
        tpl2 = tmp_path / "b.txt.tpl"
        tpl2.write_text("heap ${heap_size}")
        ext = tmp_path / "ext.txt.tpl"
        ext.write_text("debug ${debug_start_address}")
        self.run_main(
            monkeypatch,
            tmp_path,
            "--outtpl",
            f"{tpl1},{tpl2}",
            "--externaltpl",
            str(ext),
        )
        assert (tmp_path / "ext.txt").read_text() == "debug 10000000"

    def test_outfile_with_multiple_templates_rejected(self, monkeypatch, tmp_path):
        tpl = tmp_path / "a.tpl"
        tpl.write_text("x")
        with pytest.raises(SystemExit):
            self.run_main(
                monkeypatch,
                tmp_path,
                "--outtpl",
                f"{tpl},{tpl}",
                "--outfile",
                str(tmp_path / "out"),
            )

    def test_externaltpl_with_single_template_rejected(self, monkeypatch, tmp_path):
        tpl = tmp_path / "a.tpl"
        tpl.write_text("x")
        with pytest.raises(SystemExit):
            self.run_main(
                monkeypatch,
                tmp_path,
                "--outtpl",
                str(tpl),
                "--externaltpl",
                str(tpl),
            )


class TestGenerateXheepErrors:
    def test_malformed_hjson_exits(self, tmp_path):
        # A valid python config is loaded first, then mcu_gen parses the
        # hjson itself and converts the parse error into a SystemExit.
        py_cfg = tmp_path / "cfg.py"
        py_cfg.write_text(PYTHON_CFG)
        args = make_args(tmp_path, python_config=str(py_cfg))
        (tmp_path / "mcu_cfg.hjson").write_text("{ broken")
        with pytest.raises(SystemExit):
            generate_xheep(args)

    def test_pads_config_returning_none_exits(self, tmp_path):
        args = make_args(tmp_path)
        (tmp_path / "pads.py").write_text("def config(xheep):\n    return None\n")
        with pytest.raises((SystemExit, TypeError)):
            generate_xheep(args)
