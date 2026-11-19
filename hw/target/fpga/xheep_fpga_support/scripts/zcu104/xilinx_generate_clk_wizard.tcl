# Copyright 2026 X-HEEP contibutors
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Define design macros

set design_name xilinx_clk_wizard

# Create block design
create_bd_design $design_name

# Create instance and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0

set_property -dict [list \
  CONFIG.CLKIN1_JITTER_PS {33.330000000000005} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {15} \
  CONFIG.CLK_IN1_BOARD_INTERFACE {Custom} \
  CONFIG.OPTIMIZE_CLOCKING_STRUCTURE_EN {true} \
  CONFIG.PRIM_IN_FREQ {300.000} \
  CONFIG.PRIM_SOURCE {No_buffer} \
  CONFIG.USE_LOCKED {false} \
  CONFIG.USE_RESET {true} \
] [get_bd_cells clk_wiz_0]

# Create the board differential clock interface.
set clk_300mhz [create_bd_intf_port \
  -mode Slave \
  -vlnv xilinx.com:interface:diff_clock_rtl:1.0 \
  -board_intf clk_300mhz \
  CLK_IN1_D_0]
set_property -dict [list CONFIG.FREQ_HZ {300000000}] $clk_300mhz

# Create one differential input buffer shared by the Clock Wizard and MIG.
set refclk_buf [create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 refclk_buf]
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDS}] $refclk_buf

connect_bd_intf_net -intf_net CLK_IN1_D_0 [get_bd_intf_ports CLK_IN1_D_0] \
  [get_bd_intf_pins refclk_buf/CLK_IN_D]

# Export the buffer output to the MIG wrapper.
set ddr4_ref_clk [create_bd_port -dir O -type clk ddr4_ref_clk]
connect_bd_net -net shared_300mhz_refclk \
  [get_bd_pins refclk_buf/IBUF_OUT] \
  [get_bd_pins clk_wiz_0/clk_in1] \
  [get_bd_ports ddr4_ref_clk]

# Export the Clock Wizard output and its remaining unconnected pins.
make_bd_pins_external [get_bd_cells clk_wiz_0]

# Save and close block design
save_bd_design
close_bd_design $design_name

# Create wrapper
set wrapper_path [ make_wrapper -fileset sources_1 -files [ get_files -norecurse xilinx_clk_wizard.bd ] -top ]
add_files -norecurse -fileset sources_1 $wrapper_path