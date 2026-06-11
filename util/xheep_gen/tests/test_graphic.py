# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for pads.graphic: object tree rendering and floorplan SVG/HTML
generation."""

from pads.cell import Cell
from pads.dimension import Dimension
from pads.floorplan import FloorplanDimensions, Side
from pads.graphic import generate_floorplan_visuals, get_cell_tree, object_to_tree
from pads.pad import Corner, Pad, Physical
from pads.pad_ring import PadRing
from pads.pin import Inout, Input, Output


def make_floorplan():
    return FloorplanDimensions(
        die_dimensions=Dimension(3000, 3000),
        bondpad_margin={side: 5 for side in Side},
        iocell_margin={side: 10 for side in Side},
        core_margin={side: 20 for side in Side},
    )


def make_ring():
    corner_cell = Cell("CORNER", 32, 32)
    mapping = {
        Side.LEFT: [
            Corner("C0", corner_cell.copy(), None),
            [Input("left_in")],
        ],
        Side.BOTTOM: [
            Corner("C1", corner_cell.copy(), None),
            [Output("bottom_out")],
        ],
        Side.RIGHT: [
            Corner("C2", corner_cell.copy(), None),
            [Inout("right_io")],
        ],
        Side.TOP: [
            Corner("C3", corner_cell.copy(), None),
            [Input("top_in")],
            Physical("PWR", Cell("IOPWR", 25, 32), Cell("BPPWR", 20, 30)),
            Physical("FILLER", None, None),
        ],
    }
    ring = PadRing(make_floorplan(), mapping, [], {})
    # The drawing code needs the in-ring positions which are normally set by
    # space_side_by_pitch; hardcode them for the test.
    for pad in ring.pad_list:
        if not isinstance(pad, Corner):
            pad.iocell_center_to_ring_edge = 100
            pad.bondpad_center_to_ring_edge = 100
    return ring


class TestObjectTree:
    def test_leaf_value(self):
        assert object_to_tree(5, name="five") == ["└─ five: 5"]

    def test_dict_and_list_nesting(self):
        tree = "\n".join(object_to_tree({"a": 1, "b": [1, 2]}))
        assert "a: 1" in tree
        assert "[0]: 1" in tree
        assert "[1]: 2" in tree

    def test_pad_tree_skips_private_and_cells(self):
        pad = Pad(0, pins=[Input("clk")])
        pad.build()
        tree = get_cell_tree(pad)
        assert "name: clk" in tree
        # the iocell/bondpad sub-objects themselves are filtered out
        assert "IOCELL_DIGITAL" not in tree
        assert "rtl_wrapper" not in tree


class TestGenerateFloorplanVisuals:
    def test_generates_svg_and_html(self, tmp_path, capsys):
        ring = make_ring()
        base = tmp_path / "floorplan"
        generate_floorplan_visuals(make_floorplan(), ring, filename_base=str(base))

        assert "Success" in capsys.readouterr().out

        svg = (tmp_path / "floorplan.svg").read_text()
        assert svg.startswith("<svg")
        # one die outline + three margin rings + pad/corner rectangles
        assert svg.count("<rect") > 8

        html = (tmp_path / "floorplan.html").read_text()
        assert "Floorplan Visualizer" in html
        assert "IOCELL_DIGITAL" in html
        assert "Physical_Filler" in html
        assert "showTip" in html
