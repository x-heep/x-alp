# Copyright X-HEEP contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Description: Pad configuration for X-ALP
#
# Only the pads actually used by x_alp.sv are included:
#   clk, rst, uart_rx, uart_tx, jtag_*, exit_valid

from XheepGen.pads.pad_ring import PadRing
from XheepGen.pads.floorplan import Side
from XheepGen.pads.pin import Input, Output, Inout


def config() -> PadRing:
    """
    Build and return the PadRing for X-ALP.
    """

    ##############################################
    # DEFINE ALL THE AVAILABLE PINS (SIGNALS)

    digital_pins = [
        Input("clk"),
        Input("rst", attributes={"active": "low"}),
        # JTAG
        Input("jtag_tck"),
        Input("jtag_tms"),
        Input("jtag_trst", attributes={"active": "low"}),
        Input("jtag_tdi"),
        Output("jtag_tdo"),
        # UART
        Input("uart_rx"),
        Output("uart_tx"),
        # Exit / testbench
        Output("exit_valid"),
    ]

    # Generate a pin dict with all these pins
    pin_dict = {}
    for pin in digital_pins:
        pin_dict[pin.name] = pin

    ##############################################
    # MAP PINS TO PADS

    mapping = {
        Side.TOP: [
            ["clk"],
            ["rst"],
            ["jtag_tck"],
            ["jtag_tms"],
            ["jtag_trst"],
            ["jtag_tdi"],
            ["jtag_tdo"],
            ["uart_rx"],
            ["uart_tx"],
            ["exit_valid"],
        ],
    }

    # Replace the strings for their corresponding Pin element from the pins list
    mapping = {
        side: [
            ([pin_dict[p] for p in item] if isinstance(item, list) else item)
            for item in groups
        ]
        for side, groups in mapping.items()
    }

    ##############################################
    # CREATE THE PAD RING

    padring = PadRing(
        floorplan_dimensions=None,
        pin_list=list(pin_dict.values()),
        mapping=mapping,
        attributes={},
    )

    # Check the pins attached to each pad so you can do a visual-sanity check
    padring.print_pin_summary()

    return padring
