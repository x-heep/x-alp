# Copyright 2026 EPFL
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author(s): Juan Sapriza, David Mallasen
# Description: Pad configuration for X-HEEP

from xheep import XHeep
from pads.pad_ring import PadRing
from pads.floorplan import Side
from pads.pin import Input, Output, Inout


def config(xheep: XHeep) -> PadRing:
    """
    Build and return the PadRing for the design, including pin definitions and pad mapping.
    For detailed documentation and usage instructions, please refer to docs/source/Configuration/PadConfiguration.md
    """

    ##############################################
    # DEFINE ALL THE AVAILABLE PINS (SIGNALS)

    digital_pins = [
        Input("clk", module="core_v_mcu"),
        Input("rst", module="x_alp", attributes={"active": "low"}),
        Input("jtag_tck", module="core_v_mcu"),
        Input("jtag_tms", module="core_v_mcu"),
        Input("jtag_trst", module="core_v_mcu", attributes={"active": "low"}),
        Input("jtag_tdi", module="core_v_mcu"),
        Output("jtag_tdo", module="core_v_mcu"),
        Output("jtag_tdo_oe", module="core_v_mcu"),
        Input("uart_rx", module="core_v_mcu"),
        Output("uart_tx", module="core_v_mcu"),
        Output("exit_valid", module="core_v_mcu"),
    ]

    # Add all gpios at once
    # for i in range(32):
    #     digital_pins.append(Inout(f"gpio_{i}", attributes={"priority": 0}))

    # Generate a pin dict with all these pins
    pin_dict = {}
    for pin in digital_pins:
        pin_dict.update({pin.name: pin})

    ##############################################
    # MAP PINS TO PADS
    # And assign them sides. If you don't care about sides (i.e. just want to simulate and/or FPGA)
    # Just assign them all to the same side, like done here.
    # Multiple pins assigned to the same pad will be multiplexed.

    mapping = {
        Side.TOP: [
            ["clk"],
            ["rst"],
            ["jtag_tck"],
            ["jtag_tms"],
            ["jtag_trst"],
            ["jtag_tdi"],
            ["jtag_tdo"],
            ["jtag_tdo_oe"],
            ["uart_rx"],
            ["uart_tx"],
            ["exit_valid"],
        ],
    }

    # Replace the strings for their correspinding Pin element from the pins list
    mapping = {
        side: [
            ([pin_dict[p] for p in item] if isinstance(item, list) else item)
            for item in groups
        ]
        for side, groups in mapping.items()
    }

    ##############################################
    # CREATE THE PAD RING

    print("Creating the PadRing with the following mapping:")
    print(pin_dict.values())

    padring = PadRing(
        floorplan_dimensions=None,
        pin_list=list(pin_dict.values()),
        mapping=mapping,
        attributes={},
    )

    # Check the pins attached to each pad so you can do a visual-sanity check
    padring.print_pin_summary()

    return padring
