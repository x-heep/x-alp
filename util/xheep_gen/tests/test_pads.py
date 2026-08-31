# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for the pads package: cells, pins, pads, floorplan containers and
the PadRing (construction, renaming, muxing, spacing and validation)."""

import pytest

from pads.cell import Cell, iocell_d, bondpad_d
from pads.dimension import Dimension
from pads.floorplan import FloorplanDimensions, Side, Orientation
from pads.pad import Pad, Physical, Corner
from pads.pad_ring import PadRing
from pads.pin import Pin, Input, Output, Inout, Asignal


def make_floorplan(bondpad_margin=5, iocell_margin=10, core_margin=20):
    return FloorplanDimensions(
        die_dimensions=Dimension(3000, 3000),
        bondpad_margin={side: bondpad_margin for side in Side},
        iocell_margin={side: iocell_margin for side in Side},
        core_margin={side: core_margin for side in Side},
    )


def make_ring(mapping, pin_list=None, attributes=None):
    return PadRing(
        floorplan_dimensions=make_floorplan(),
        mapping=mapping,
        pin_list=[] if pin_list is None else pin_list,
        attributes={} if attributes is None else attributes,
    )


class TestDimension:
    def test_str(self):
        assert str(Dimension(20, 30)) == "30×20µm"

    def test_negative_rejected(self):
        with pytest.raises(ValueError):
            Dimension(-1, 10)


class TestCell:
    def test_update_returns_self(self):
        cell = Cell("C", 10, 20)
        assert cell.update(rtl_wrapper="wrap") is cell
        assert cell.rtl_wrapper == "wrap"

    def test_update_verbose_prints(self, capsys):
        Cell("C", 10, 20).update(name="D", verbose=True)
        assert "Updating C" in capsys.readouterr().out

    def test_copy_is_independent(self):
        cell = Cell("C", 10, 20, connections=["vdd"])
        clone = cell.copy()
        clone.connections.append("vss")
        assert cell.connections == ["vdd"]


class TestPin:
    def test_defaults(self):
        pin = Pin("clk")
        assert pin.module == Pin.DEFAULT_MODULE
        assert pin.attributes == {}
        assert str(pin) == "clk"

    def test_custom_module(self):
        assert Pin("clk", module="periph").module == "periph"

    def test_rtl_name_suffix(self):
        assert Pin("clk").rtl_name() == "clk_"
        assert Pin("rst", attributes={"active": "low"}).rtl_name() == "rst_n"

    def test_digital_pin_wrappers(self):
        assert Input("a").iocell.rtl_wrapper == "pad_cell_input"
        assert Output("b").iocell.rtl_wrapper == "pad_cell_output"
        assert Inout("c").iocell.rtl_wrapper == "pad_cell_inout"

    def test_digital_pin_cells_are_copies(self):
        pin = Input("a")
        pin.iocell.name = "CHANGED"
        assert iocell_d.name == "IOCELL_DIGITAL"
        assert bondpad_d.name == "BONDPAD_DIGITAL"

    def test_analog_pin(self):
        pin = Asignal("vref")
        assert pin.iocell.name == "IOCELL_ANALOG"
        assert pin.bondpad.name == "BONDPAD_ANALOG"


class TestPad:
    def test_build_inherits_main_pin(self):
        pad = Pad(0, pins=[Input("a", attributes={"active": "low"})])
        pad.build()
        assert pad.name == "a"
        assert pad.attributes == {"active": "low"}
        assert pad.iocell.rtl_wrapper == "pad_cell_input"

    def test_build_orders_pins_by_priority(self):
        low = Input("low", attributes={"priority": 1})
        high = Input("high", attributes={"priority": 2})
        pad = Pad(0, pins=[low, high])
        pad.build()
        assert pad.pins[0] is high
        assert pad.name == "high"

    def test_build_without_priority_keeps_order(self):
        first, second = Input("first"), Input("second")
        pad = Pad(0, pins=[first, second])
        pad.build()
        assert pad.pins[0] is first

    def test_is_muxed(self):
        assert not Pad(0, pins=[Input("a")]).is_muxed()
        assert Pad(0, pins=[Input("a"), Input("b")]).is_muxed()

    def test_build_without_pins_is_noop(self):
        pad = Pad(0)
        pad.build()
        assert pad.name == ""

    def test_physical(self):
        phys = Physical("PRCUT", iocell=Cell("CUT", 5, 32), bondpad=None)
        assert phys.name == "PRCUT"
        assert phys.pins == []
        assert phys.attributes == {}


class TestFloorplanDimensions:
    def test_margin_must_have_four_sides(self):
        with pytest.raises(ValueError, match="four elements"):
            FloorplanDimensions(
                Dimension(100, 100),
                bondpad_margin={Side.LEFT: 1},
                iocell_margin={side: 1 for side in Side},
                core_margin={side: 1 for side in Side},
            )

    def test_negative_margin_rejected(self):
        margins = {side: 1 for side in Side}
        bad = {**margins, Side.TOP: -1}
        with pytest.raises(ValueError, match="non-negative"):
            FloorplanDimensions(Dimension(100, 100), margins, bad, margins)


class TestPadRingConstruction:
    def test_pads_from_pin_lists(self):
        ring = make_ring(
            {Side.LEFT: [[Input("a")], [Input("b")]], Side.TOP: [[Input("c")]]}
        )
        assert [pad.name for pad in ring.pad_list] == ["a", "b", "c"]
        assert ring.pad_list[0].global_index == 0
        assert ring.pad_list[1].side_index == 1
        assert ring.pad_list[0].orientation == Orientation.R90
        assert ring.pad_list[2].orientation == Orientation.R0

    def test_premade_pad_is_copied_and_indexed(self):
        pad = Pad(global_index=None, pins=[Input("a")])
        ring = make_ring({Side.LEFT: [pad]})
        assert ring.pad_list[0] is not pad
        assert ring.pad_list[0].global_index == 0

    def test_physical_pad_keeps_no_global_index(self):
        corner = Corner("CORNER", iocell=Cell("C", 32, 32), bondpad=None)
        ring = make_ring({Side.LEFT: [corner, [Input("a")]]})
        assert ring.pad_list[0].global_index is None
        assert ring.pad_list[1].global_index == 0

    def test_invalid_mapping_entry_rejected(self):
        with pytest.raises(ValueError, match="mapping"):
            make_ring({Side.LEFT: ["not-a-pad"]})

    def test_duplicate_names_are_renamed(self):
        ring = make_ring({Side.LEFT: [[Input("gpio")], [Input("gpio")]]})
        assert [pad.name for pad in ring.pad_list] == ["gpio_1", "gpio_2"]

    def test_pad_with_none_name_gets_nc_name(self):
        pad = Pad(global_index=7)
        pad.name = None
        ring = make_ring({Side.LEFT: [pad]})
        assert ring.pad_list[0].name == "NC_7"


class TestPadRingQueries:
    def make_muxed_ring(self):
        self.a, self.b, self.c = Input("a"), Input("b"), Input("c")
        self.unconnected = Input("nc")
        return make_ring(
            {Side.LEFT: [[self.a, self.b], [self.c]]},
            pin_list=[self.a, self.b, self.c, self.unconnected],
        )

    def test_get_connected_pins(self):
        ring = self.make_muxed_ring()
        assert ring.get_connected_pins() == [self.a, self.b, self.c]

    def test_get_connected_main_pins(self):
        ring = self.make_muxed_ring()
        assert ring.get_connected_main_pins() == [self.a, self.c]

    def test_num_muxed_pads(self):
        assert self.make_muxed_ring().num_muxed_pads() == 1

    def test_muxed_pad_select_width(self):
        assert self.make_muxed_ring().get_muxed_pad_select_width() == 1
        plain = make_ring({Side.LEFT: [[Input("a")]]})
        assert plain.get_muxed_pad_select_width() == 0
        wide = make_ring({Side.LEFT: [[Input("a"), Input("b"), Input("c")]]})
        assert wide.get_muxed_pad_select_width() == 2

    def test_print_pin_summary(self, capsys):
        ring = self.make_muxed_ring()
        ring.print_pin_summary()
        out = capsys.readouterr().out
        assert "a, b" in out
        assert "UNCONNCETED PINS" in out
        assert "- nc" in out


class TestPadRingValidate:
    def test_no_bits_attribute_passes(self):
        make_ring({Side.LEFT: [[Input("a")]]}).validate()

    def test_valid_bits_and_resval_pass(self):
        ring = make_ring(
            {Side.LEFT: [[Input("a")]]}, attributes={"bits": "7:0", "resval": 255}
        )
        ring.validate()

    @pytest.mark.parametrize(
        "attributes,message",
        [
            ({"bits": 7}, "not a string"),
            ({"bits": "70"}, "not a string"),
            ({"bits": "a:b"}, "valid integers"),
            ({"bits": "0:7"}, "less than lsb"),
            ({"bits": "7:0"}, "resval"),
            ({"bits": "7:0", "resval": 256}, "does not fit"),
        ],
    )
    def test_invalid_attributes_rejected(self, attributes, message):
        ring = make_ring({Side.LEFT: [[Input("a")]]}, attributes=attributes)
        with pytest.raises(RuntimeError, match=message):
            ring.validate()


class TestSpaceSideByPitch:
    # Digital iocells are 25x32 um and bondpads 20x30 um (see pads.cell);
    # margins come from make_floorplan (iocell 10, bondpad 5).

    def test_two_pads_spaced_by_pitch(self):
        ring = make_ring({Side.LEFT: [[Input("a")], [Input("b")]]})
        ring.space_side_by_pitch(Side.LEFT, space_from_corner_cell=10, pitch=90)
        first, second = ring.pad_list

        assert first.space == 10
        # corner width (= iocell height 32) + 10 + half iocell width
        assert first.iocell_center_to_ring_edge == pytest.approx(54.5)
        assert second.space == pytest.approx(90 - 25)
        assert second.iocell_center_to_ring_edge == pytest.approx(144.5)

        # bondpads: margin_diff 5, width diff (25-20)/2
        assert first.offset == pytest.approx(5 + 32 + 10 + 2.5)
        assert first.bondpad_center_to_ring_edge == pytest.approx(59.5)
        assert second.bondpad_center_to_ring_edge == pytest.approx(149.5)
        assert second.bp_space == pytest.approx(90 - 20)

    def test_hardcoded_center_is_respected(self):
        ring = make_ring({Side.LEFT: [[Input("a")], [Input("b")]]})
        ring.pad_list[1].iocell_center_to_ring_edge = 200
        ring.space_side_by_pitch(Side.LEFT, space_from_corner_cell=10, pitch=90)
        second = ring.pad_list[1]
        assert second.iocell_center_to_ring_edge == pytest.approx(200)
        assert second.space == pytest.approx(200 - 54.5 - 25)

    def test_pad_without_bondpad_in_the_middle(self):
        prcut = Physical("PRCUT", iocell=Cell("CUT", 5, 32), bondpad=None)
        ring = make_ring({Side.LEFT: [[Input("a")], prcut, [Input("b")]]})
        ring.space_side_by_pitch(Side.LEFT, space_from_corner_cell=10, pitch=90)
        first, cut, last = ring.pad_list

        assert cut.space == 0
        # The pad after the cut compensates: pitch minus the gap taken by the
        # half-widths of the surrounding cells and the PRCUT itself.
        assert last.space == pytest.approx(90 - (12.5 + 5 + 12.5))
        assert not hasattr(cut, "bp_space")
        assert last.bp_space == pytest.approx(
            last.bondpad_center_to_ring_edge - first.bondpad_center_to_ring_edge - 20
        )

    def test_empty_side_warns_and_returns(self, capsys):
        ring = make_ring({Side.LEFT: [[Input("a")]]})
        ring.space_side_by_pitch(Side.TOP, space_from_corner_cell=10, pitch=90)
        assert "No pads found" in capsys.readouterr().out

    def test_corners_are_excluded(self, capsys):
        corner = Corner("CORNER", iocell=Cell("C", 32, 32), bondpad=None)
        ring = make_ring({Side.LEFT: [corner]})
        ring.space_side_by_pitch(Side.LEFT, space_from_corner_cell=10, pitch=90)
        assert "No pads found" in capsys.readouterr().out

    def test_missing_side_index_rejected(self):
        ring = make_ring({Side.LEFT: [[Input("a")]]})
        ring.pad_list[0].side_index = None
        with pytest.raises(ValueError, match="side_index"):
            ring.space_side_by_pitch(Side.LEFT, space_from_corner_cell=10, pitch=90)

    def test_first_pad_without_bondpad_rejected(self):
        prcut = Physical("PRCUT", iocell=Cell("CUT", 5, 32), bondpad=None)
        ring = make_ring({Side.LEFT: [prcut, [Input("a")]]})
        with pytest.raises(ValueError, match="without bondpad"):
            ring.space_side_by_pitch(Side.LEFT, space_from_corner_cell=10, pitch=90)
