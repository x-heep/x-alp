# Copyright 2026 X-HEEP contibutors
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# Board 300 MHz reference: Vivado derives the SoC (Clock Wizard) and DDR4 (MIG) clocks from it.
create_clock -add -name sys_clk_pin -period 3.333 -waveform {0 1.666} [get_ports {clk_300mhz_p}];
create_clock -add -name jtag_clk_pin -period 100.00 -waveform {0 5} [get_ports {jtag_tck_i}];
create_clock -add -name spi_slave_clk_pin -period 16.00 -waveform {0 5} [get_ports {spi_slave_sck_io}];
