# Copyright 2026 X-HEEP contibutors
#
# File: set_tcl_hooks.tcl
# Author: Christian Conti {christian.conti@polito.it}
# Date: 15/10/2026
#
# Sourced by FuseSoC/Edalize during project setup

set design_name xilinx_ddr4_ctrl_wizard

# Create block design
create_bd_design $design_name

# Create interface ports
# Use the ZCU104 board DDR4 pin map for the external interface.
set ddr4_sdram [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 -board_intf ddr4_sdram ddr4_sdram]
set S_AXI [create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI]
# ID_WIDTH and C0.DDR4_AxiIDWidth must equal core_v_mcu_pkg::AxiLlcIdWidth.
set_property -dict [list \
  CONFIG.ADDR_WIDTH {32} \
  CONFIG.ARUSER_WIDTH {0} \
  CONFIG.AWUSER_WIDTH {0} \
  CONFIG.BUSER_WIDTH {0} \
  CONFIG.DATA_WIDTH {64} \
  CONFIG.HAS_BRESP {1} \
  CONFIG.HAS_BURST {1} \
  CONFIG.HAS_CACHE {1} \
  CONFIG.HAS_LOCK {1} \
  CONFIG.HAS_PROT {1} \
  CONFIG.HAS_QOS {1} \
  CONFIG.HAS_REGION {1} \
  CONFIG.HAS_RRESP {1} \
  CONFIG.HAS_WSTRB {1} \
  CONFIG.ID_WIDTH {7} \
  CONFIG.MAX_BURST_LENGTH {256} \
  CONFIG.NUM_READ_OUTSTANDING {2} \
  CONFIG.NUM_READ_THREADS {1} \
  CONFIG.NUM_WRITE_OUTSTANDING {2} \
  CONFIG.NUM_WRITE_THREADS {1} \
  CONFIG.PROTOCOL {AXI4} \
  CONFIG.READ_WRITE_MODE {READ_WRITE} \
  CONFIG.RUSER_BITS_PER_BYTE {0} \
  CONFIG.RUSER_WIDTH {0} \
  CONFIG.SUPPORTS_NARROW_BURST {1} \
  CONFIG.WUSER_BITS_PER_BYTE {0} \
  CONFIG.WUSER_WIDTH {0} \
] $S_AXI

# Create ports
set s_axi_aclk [create_bd_port -dir I -type clk s_axi_aclk]
set s_axi_aresetn [create_bd_port -dir I -type rst s_axi_aresetn]
set sys_rst [create_bd_port -dir I -type rst sys_rst]
set_property -dict [list CONFIG.POLARITY {ACTIVE_HIGH}] $sys_rst

# Expose the buffered 300 MHz reference clock at the block-design boundary.
# The top-level wrapper maps this clock to the MIG input.
set c0_sys_clk_i [create_bd_port -dir I -type clk -freq_hz 300000000 c0_sys_clk_i]

# Create instance: ddr4_0, and set properties
set ddr4_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 ddr4_0]
set_property -dict [list \
  CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {100} \
  CONFIG.C0.DDR4_AxiAddressWidth {32} \
  CONFIG.C0.DDR4_AxiIDWidth {7} \
  CONFIG.C0.DDR4_InputClockPeriod {3333} \
  CONFIG.C0_CLOCK_BOARD_INTERFACE {Custom} \
  CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram} \
  CONFIG.RESET_BOARD_INTERFACE {Custom} \
  CONFIG.System_Clock {No Buffer} \
] $ddr4_0

# Create instance: axi_dwidth_converter_0
set axi_dwidth_converter_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:2.1 axi_dwidth_converter_0]
# Always pack LLC line bursts into full 512-bit beats: the default (1) packs only
# modifiable AxCACHE, and the LLC forwards the requester's (non-modifiable) attribute.
set_property CONFIG.PACKING_LEVEL {2} $axi_dwidth_converter_0

# Create instance: axi_clock_converter_0
set axi_clock_converter_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_0]

# Create instance: rst_ddr4_0_266M
set rst_ddr4_0_266M [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ddr4_0_266M]

# Create interface connections
connect_bd_intf_net -intf_net S_AXI_0_1 [get_bd_intf_ports S_AXI] [get_bd_intf_pins axi_clock_converter_0/S_AXI]
connect_bd_intf_net -intf_net axi_clock_converter_0_M_AXI [get_bd_intf_pins axi_clock_converter_0/M_AXI] [get_bd_intf_pins axi_dwidth_converter_0/S_AXI]
connect_bd_intf_net -intf_net axi_dwidth_converter_0_M_AXI [get_bd_intf_pins axi_dwidth_converter_0/M_AXI] [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram] [get_bd_intf_pins ddr4_0/C0_DDR4]

# Connect ports
connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins ddr4_0/c0_ddr4_ui_clk] \
  [get_bd_pins axi_clock_converter_0/m_axi_aclk] \
  [get_bd_pins axi_dwidth_converter_0/s_axi_aclk] \
  [get_bd_pins rst_ddr4_0_266M/slowest_sync_clk]
connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] \
  [get_bd_pins rst_ddr4_0_266M/ext_reset_in]
connect_bd_net -net reset_1 [get_bd_ports sys_rst] \
  [get_bd_pins ddr4_0/sys_rst]
connect_bd_net -net rst_ddr4_0_266M_peripheral_aresetn [get_bd_pins rst_ddr4_0_266M/peripheral_aresetn] \
  [get_bd_pins axi_dwidth_converter_0/s_axi_aresetn] \
  [get_bd_pins axi_clock_converter_0/m_axi_aresetn] \
  [get_bd_pins ddr4_0/c0_ddr4_aresetn]
connect_bd_net -net s_axi_aclk_0_1 [get_bd_ports s_axi_aclk] \
  [get_bd_pins axi_clock_converter_0/s_axi_aclk]
connect_bd_net -net s_axi_aresetn_0_1 [get_bd_ports s_axi_aresetn] \
  [get_bd_pins axi_clock_converter_0/s_axi_aresetn]
connect_bd_net -net c0_sys_clk_i_0_1 [get_bd_ports c0_sys_clk_i] \
  [get_bd_pins ddr4_0/c0_sys_clk_i]

# Create address segments

# Save and close block design
save_bd_design
close_bd_design $design_name

# Create wrapper
set wrapper_path [make_wrapper -fileset sources_1 -files [get_files -norecurse xilinx_ddr4_ctrl_wizard.bd] -top]
add_files -norecurse -fileset sources_1 $wrapper_path
