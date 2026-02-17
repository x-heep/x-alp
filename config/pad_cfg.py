# Copyright X-HEEP contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Description: Pad configuration for X-ALP

from XheepGen.pads.pad_ring import PadRing
from XheepGen.pads.floorplan import Side
from XheepGen.pads.pin import Input, Output, Inout


def config() -> PadRing:
    """
    Build and return the PadRing for the design, including pin definitions and pad mapping.
    """

    ##############################################
    # DEFINE ALL THE AVAILABLE PINS (SIGNALS)

    digital_pins = [
        Input("clk"),
        Input("rst", attributes={"active": "low"}),
        Input("boot_select"),
        Input("execute_from_flash"),
        Input("jtag_tck"),
        Input("jtag_tms"),
        Input("jtag_trst", attributes={"active": "low"}),
        Input("jtag_tdi"),
        Output("jtag_tdo"),
        Input("uart_rx"),
        Output("uart_tx"),
        Output("exit_valid"),
        Inout("spi_flash_sck"),
        Inout("spi_flash_cs_0"),
        Inout("spi_flash_cs_1"),
        Inout("spi_flash_sd_0"),
        Inout("spi_flash_sd_1"),
        Inout("spi_flash_sd_2"),
        Inout("spi_flash_sd_3"),
        Inout("spi_sck"),
        Inout("spi_cs_0"),
        Inout("spi_cs_1"),
        Inout("spi_sd_0"),
        Inout("spi_sd_1"),
        Inout("spi_sd_2"),
        Inout("spi_sd_3"),
        Input("spi_slave_sck"),
        Input("spi_slave_cs"),
        Inout("spi_slave_miso"),
        Input("spi_slave_mosi"),
        Inout("pdm2pcm_pdm"),
        Inout("pdm2pcm_clk"),
        Inout("i2s_sck"),
        Inout("i2s_ws"),
        Inout("i2s_sd"),
        Inout("spi2_cs_0"),
        Inout("spi2_cs_1"),
        Inout("spi2_sck"),
        Inout("spi2_sd_0"),
        Inout("spi2_sd_1"),
        Inout("spi2_sd_2"),
        Inout("spi2_sd_3"),
        Inout("i2c_scl"),
        Inout("i2c_sda"),
    ]

    # Add GPIOs
    for i in range(32):
        digital_pins.append(Inout(f"gpio_{i}", attributes={"priority": 0}))

    # Generate a pin dict with all these pins
    pin_dict = {}
    for pin in digital_pins:
        pin_dict.update({pin.name: pin})

    ##############################################
    # MAP PINS TO PADS
    # Multiple pins assigned to the same pad will be multiplexed.

    mapping = {
        Side.TOP: [
            ["clk"],
            ["rst"],
            ["boot_select"],
            ["execute_from_flash"],
            ["jtag_tck"],
            ["jtag_tms"],
            ["jtag_trst"],
            ["jtag_tdi"],
            ["jtag_tdo"],
            ["uart_rx"],
            ["uart_tx"],
            ["exit_valid"],
            ["gpio_0"],
            ["gpio_1"],
            ["gpio_2"],
            ["gpio_3"],
            ["gpio_4"],
            ["gpio_5"],
            ["gpio_6"],
            ["gpio_7"],
            ["gpio_8"],
            ["gpio_9"],
            ["gpio_10"],
            ["gpio_11"],
            ["gpio_12"],
            ["gpio_13"],
            ["spi_flash_sck"],
            ["spi_flash_cs_0"],
            ["spi_flash_cs_1"],
            ["spi_flash_sd_0"],
            ["spi_flash_sd_1"],
            ["spi_flash_sd_2"],
            ["spi_flash_sd_3"],
            ["spi_sck"],
            ["spi_cs_0"],
            ["spi_cs_1"],
            ["spi_sd_0"],
            ["spi_sd_1"],
            ["spi_sd_2"],
            ["spi_sd_3"],
            ["spi_slave_sck", "gpio_14"],
            ["spi_slave_cs", "gpio_15"],
            ["spi_slave_miso", "gpio_16"],
            ["spi_slave_mosi", "gpio_17"],
            ["pdm2pcm_pdm", "gpio_18"],
            ["pdm2pcm_clk", "gpio_19"],
            ["i2s_sck", "gpio_20"],
            ["i2s_ws", "gpio_21"],
            ["i2s_sd", "gpio_22"],
            ["spi2_cs_0", "gpio_23"],
            ["spi2_cs_1", "gpio_24"],
            ["spi2_sck", "gpio_25"],
            ["spi2_sd_0", "gpio_26"],
            ["spi2_sd_1", "gpio_27"],
            ["spi2_sd_2", "gpio_28"],
            ["spi2_sd_3", "gpio_29"],
            ["i2c_scl", "gpio_31"],
            ["i2c_sda", "gpio_30"],
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
