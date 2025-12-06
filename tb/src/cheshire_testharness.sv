// Copyright 2025 EPFL and Politecnico di Torino.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// File: cheshire_testharness.sv
// Author: Flavia Guella
// Date: 03/12/2025
// Inspired by x-heep testharness.sv



module cheshire_testharness #(
  /// The selected simulation configuration from the `tb_cheshire_pkg`.
  parameter int unsigned SelectedCfg = 32'd0,
  parameter bit          UseDramSys  = 1'b0,
  parameter int unsigned DRAM_LATENCY = 32'd1,
  parameter bit          USE_JTAG_DPI  = 1'b0
) (
  input logic       clk_i,
  input logic       rst_ni,
  input logic       test_mode_i,
  // Boot mode
  //----------
  input logic [1:0] boot_mode_i,

  // RTC Clic clock
  // --------------
  input logic       rtc_i,

  // ELF to be loaded
  // ----------------
  //input string      preload_elf,
  
  // JTAG
  // ----
  input  logic         jtag_tck_i,
  input  logic         jtag_tms_i,
  input  logic         jtag_trst_ni,
  input  logic         jtag_tdi_i,
  output logic         jtag_tdo_o,
  // Exit sim
  // --------
  output logic [31:0] exit_value_o,
  output logic        exit_valid_o
);

// Includes
// --------
`include "cheshire/typedef.svh"
`include "tb_cheshire_util.svh"

// Package import
// --------------
import cheshire_pkg::*;
import tb_cheshire_pkg::*;


// LLC Config
// ----------
// TODO: this might be changed, do part of it in the top tb
localparam cheshire_cfg_t DutCfg = TbCheshireConfigs[SelectedCfg];

`CHESHIRE_TYPEDEF_ALL(, DutCfg)

// Internal signals
// ----------------

// JTAG
logic sim_jtag_enable;
logic sim_jtag_tck;
logic sim_jtag_trst_n;
logic sim_jtag_tms;
logic sim_jtag_tdi;
logic sim_jtag_tdo;

logic jtag_tck;
logic jtag_trst_n;
logic jtag_tms;
logic jtag_tdi;
logic jtag_tdo;

// UART
logic uart_tx;
logic uart_rx;
// I2C
logic i2c_sda;
logic i2c_scl;
// SPI
logic [3:0] spih_sd;
// Serial Link
logic [SlinkNumChan-1:0]                    slink_rcv_clk;
logic [SlinkNumChan-1:0][SlinkNumLanes-1:0] slink;

// DRAM
axi_llc_req_t axi_llc_mst_req;
axi_llc_rsp_t axi_llc_mst_rsp;

//----
// DUT
//----
  cheshire_soc #(
    .Cfg                ( DutCfg ),
    .ExtHartinfo        ( '0 ),
    .axi_ext_llc_req_t  ( axi_llc_req_t ),
    .axi_ext_llc_rsp_t  ( axi_llc_rsp_t ),
    .axi_ext_mst_req_t  ( axi_mst_req_t ),
    .axi_ext_mst_rsp_t  ( axi_mst_rsp_t ),
    .axi_ext_slv_req_t  ( axi_slv_req_t ),
    .axi_ext_slv_rsp_t  ( axi_slv_rsp_t ),
    .reg_ext_req_t      ( reg_req_t ),
    .reg_ext_rsp_t      ( reg_rsp_t )
  ) i_cheshire_soc (
    .clk_i              ( clk_i       ),
    .rst_ni             ( rst_ni     ),
    .test_mode_i        ( test_mode_i ),
    .boot_mode_i        ( boot_mode_i ),
    .rtc_i              ( rtc_i       ),
    .axi_llc_mst_req_o  ( axi_llc_mst_req ),
    .axi_llc_mst_rsp_i  ( axi_llc_mst_rsp ),
    .axi_ext_mst_req_i  ( '0 ),
    .axi_ext_mst_rsp_o  ( ),
    .axi_ext_slv_req_o  ( ),
    .axi_ext_slv_rsp_i  ( '0 ),
    .reg_ext_slv_req_o  ( ),
    .reg_ext_slv_rsp_i  ( '0 ),
    .intr_ext_i         ( '0 ),
    .intr_ext_o         ( ),
    .xeip_ext_o         ( ),
    .mtip_ext_o         ( ),
    .msip_ext_o         ( ),
    .dbg_active_o       ( ),
    .dbg_ext_req_o      ( ),
    .dbg_ext_unavail_i  ( '0 ),
    .jtag_tck_i         ( jtag_tck    ),
    .jtag_trst_ni       ( jtag_trst_n ),
    .jtag_tms_i         ( jtag_tms    ),
    .jtag_tdi_i         ( jtag_tdi    ),
    .jtag_tdo_o         ( jtag_tdo    ),
    .jtag_tdo_oe_o      ( ),
    .uart_tx_o          ( uart_tx ),
    .uart_rx_i          ( uart_rx ),
    .uart_rts_no        ( ),
    .uart_dtr_no        ( ),
    .uart_cts_ni        ( 1'b0 ),
    .uart_dsr_ni        ( 1'b0 ),
    .uart_dcd_ni        ( 1'b0 ),
    .uart_rin_ni        ( 1'b0 ),
    .i2c_sda_o          ( ),
    .i2c_sda_i          ( i2c_sda  ),
    .i2c_sda_en_o       ( ),
    .i2c_scl_o          ( ),
    .i2c_scl_i          ( i2c_scl  ),
    .i2c_scl_en_o       ( ),
    .spih_sck_o         ( ),
    .spih_sck_en_o      ( ),
    .spih_csb_o         ( ),
    .spih_csb_en_o      ( ),
    .spih_sd_o          ( ),
    .spih_sd_en_o       ( ),
    .spih_sd_i          ( spih_sd     ),
    .gpio_i             ( '0 ),
    .gpio_o             ( ),
    .gpio_en_o          ( ),
    .slink_rcv_clk_i    ( slink_rcv_clk ),
    .slink_rcv_clk_o    ( ),
    .slink_i            ( slink ),
    .slink_o            ( ),
    .vga_hsync_o        ( ),
    .vga_vsync_o        ( ),
    .vga_red_o          ( ),
    .vga_green_o        ( ),
    .vga_blue_o         ( ),
    .usb_clk_i          ( 1'b0 ),
    .usb_rst_ni         ( 1'b1 ),
    .usb_dm_i           ( '0 ),
    .usb_dm_o           ( ),
    .usb_dm_oe_o        ( ),
    .usb_dp_i           ( '0 ),
    .usb_dp_o           ( ),
    .usb_dp_oe_o        ( )
  );

// UNSUPPORTED FEATURES in VERILATOR
`ifdef VERILATOR
  // I2C
  // ---
  assign i2c_sda        = 1'b0;
  assign i2c_scl        = 1'b0;
  // SPI
  // ---
  assign spih_sd        = 4'b0;
  // Serial Link
  // -----------
  assign slink_rcv_clk = '0;
  assign slink         = '0;

`endif


//-----------
// Ext Periph
//-----------
`ifndef VERILATOR
axi_mst_req_t axi_slink_mst_req;
axi_mst_rsp_t axi_slink_mst_rsp;

assign axi_slink_mst_req = '0;
`endif

vip_cheshire_soc #(
  .DutCfg            ( DutCfg        ),
  .UseDramSys        ( UseDramSys    ),
  .UseJtagDPI        ( USE_JTAG_DPI  ),
  .DramLatency       ( DRAM_LATENCY  ),
  .axi_ext_llc_req_t ( axi_llc_req_t ),
  .axi_ext_llc_rsp_t ( axi_llc_rsp_t ),
  .axi_ext_mst_req_t ( axi_mst_req_t ),
  .axi_ext_mst_rsp_t ( axi_mst_rsp_t )
) vip (
  .clk (clk_i),
  .rst_n (rst_ni),
  // TODO:Connect other signals
  .axi_llc_mst_req(axi_llc_mst_req),
  .axi_llc_mst_rsp(axi_llc_mst_rsp),
  // JTAG
  .jtag_tck(sim_jtag_tck),
  .jtag_trst_n(sim_jtag_trst_n),
  .jtag_tms(sim_jtag_tms),
  .jtag_tdi(sim_jtag_tdi),
  .jtag_tdo(sim_jtag_tdo),
  .uart_tx(uart_tx),
  `ifndef VERILATOR
  .uart_rx(uart_rx),
  .test_mode(),
  .boot_mode(boot_mode_i),
  .axi_slink_mst_req(axi_slink_mst_req),
  .axi_slink_mst_rsp(),
  .i2c_sda(), // unsupported in verilator
  .i2c_scl(), // unsupported in verilator
  .spih_sck(), // unsupported in verilator
  .spih_csb(), // unsupported in verilator
  .spih_sd( ), // unsupported in verilator
  .slink_rcv_clk_i(slink_rcv_clk),
  .slink_rcv_clk_o('0),
  .slink_i(slink),
  .slink_o('0)
  `else
  .uart_rx(uart_rx)
  `endif
);

// JTAG BOOT MODE
// --------------
assign sim_jtag_enable = (boot_mode_i == 0 && USE_JTAG_DPI) ? 1'b1 : 1'b0;
assign jtag_tck        = (sim_jtag_enable) ? sim_jtag_tck : jtag_tck_i;
assign jtag_trst_n     = (sim_jtag_enable) ? sim_jtag_trst_n : jtag_trst_ni;
assign jtag_tms        = (sim_jtag_enable) ? sim_jtag_tms : jtag_tms_i;
assign jtag_tdi        = (sim_jtag_enable) ? sim_jtag_tdi : jtag_tdi_i;
assign sim_jtag_tdo    = (sim_jtag_enable) ? jtag_tdo : 1'b0;
assign jtag_tdo_o      = (sim_jtag_enable) ? 1'b0 : jtag_tdo;


//------------
// Exit values
//------------
assign exit_valid_o =  i_cheshire_soc.i_regs.u_scratch_2.q[0];
assign exit_value_o = (exit_valid_o) ? {1'b0, i_cheshire_soc.i_regs.u_scratch_2.q[31:1]} : 32'd1;


endmodule

