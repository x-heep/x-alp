// Copyright 2022 EPFL
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1



module spi_subsystem
  import core_v_mini_mcu_pkg::*;
  import spi_host_reg_pkg::*;
#(
    parameter int DataWidth = 64,
    parameter int AddrWidth = 64,
    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic,
    parameter type axi_req_t = logic,
    parameter type axi_resp_t = logic,
    parameter int ClockFrequencyMAX_MHz = 1e3,
    parameter logic ByteOrder = 1  // 1 = little endian , 0 = big endian

)(

    input logic clk_i,
    input logic rst_ni,


    // AXI interface
    input  axi_req_t  axi_req_i,
    output axi_resp_t axi_rsp_o,

    // spi_subsystem configuration interface (reg)
    input  reg_req_t  top_reg_req_i, 
    output reg_rsp_t  top_reg_rsp_o,

    // spi_host data and configuration interface
    input  reg_req_t  spihost_reg_req_i,
    output reg_rsp_t  spihost_reg_rsp_o,


    // SPI Interface
    output logic                               spi_flash_sck_o,
    output logic                               spi_flash_sck_en_o,
    output logic [spi_host_reg_pkg::NumCS-1:0] spi_flash_csb_o,
    output logic [spi_host_reg_pkg::NumCS-1:0] spi_flash_csb_en_o,
    output logic [                        3:0] spi_flash_sd_o,
    output logic [                        3:0] spi_flash_sd_en_o,
    input  logic [                        3:0] spi_flash_sd_i,

    // spi_host interrupts
    output logic spi_flash_intr_error_o,
    output logic spi_flash_intr_event_o,

    // spi_host data fifos handshake to DMA
    output logic spi_flash_rx_valid_o,
    output logic spi_flash_tx_ready_o

);


  // OpenTitan SPI Interface
  logic                               ot_spi_sck;
  logic                               ot_spi_sck_en;
  logic [spi_host_reg_pkg::NumCS-1:0] ot_spi_csb;
  logic [spi_host_reg_pkg::NumCS-1:0] ot_spi_csb_en;
  logic [                        3:0] ot_spi_sd_out;
  logic [                        3:0] ot_spi_sd_en;
  logic [                        3:0] ot_spi_sd_in;
  logic                               ot_spi_intr_error;
  logic                               ot_spi_intr_event;
  logic                               ot_spi_rx_valid;
  logic                               ot_spi_tx_ready;

  spi_host_reg_pkg::spi_host_hw2reg_status_reg_t external_spi_host_hw2reg_status;


always_comb begin
  spi_flash_sck_o = ot_spi_sck;
  spi_flash_sck_en_o = ot_spi_sck_en;
  spi_flash_csb_o = ot_spi_csb;
  spi_flash_csb_en_o = ot_spi_csb_en;
  spi_flash_sd_o = ot_spi_sd_out;
  spi_flash_sd_en_o = ot_spi_sd_en;
  ot_spi_sd_in = spi_flash_sd_i;
  spi_flash_intr_error_o = ot_spi_intr_error;
  spi_flash_intr_event_o = ot_spi_intr_event;
  spi_flash_rx_valid_o = ot_spi_rx_valid;
  spi_flash_tx_ready_o = ot_spi_tx_ready;
end



  // AXI to flash controller
  reg_req_t reg_req_from_a2f_ctr;
  reg_rsp_t reg_rsp_to_a2f_ctr;

  axi_to_flash_controller #(
      .ByteOrder,
      .AddrWidth,   // behavior differs depending from dataWidth, generated HW is always the same.
      .ClockFrequencyMAX_MHz,
      .FlashAddrW(24),
      .DataWidth,
      .axi_req_t(axi_req_t),
      .axi_resp_t(axi_resp_t),
      .reg_req_t(reg_req_t),
      .reg_rsp_t(reg_rsp_t)
  ) axi_to_flash_controller_i (
      .clk_i,
      .rst_ni,

      // Enable by xspi register
      .en_i(reg2hw.control.use_axi.q),

      // Enable power-on subrutine
      .poweron_en_i(reg2hw.control.a2f_ctr_poweron_en.q),

      // register interface to SPI controller
      .spi_host_reg_req_o(reg_req_from_a2f_ctr),
      .spi_host_reg_rsp_i(reg_rsp_to_a2f_ctr),

      // SPI controller status direct connection from hw2reg
      .external_spi_host_hw2reg_status_i(external_spi_host_hw2reg_status),

      // AXI interface
      .axi_req_i(axi_req_i),
      .axi_rsp_o(axi_rsp_o)
  );


  reg_req_t muxed_controllers_reg_req;
  reg_rsp_t muxed_controllers_reg_rsp;



 
  assign muxed_controllers_reg_req = reg_req_from_a2f_ctr;
  assign reg_rsp_to_a2f_ctr = muxed_controllers_reg_rsp;



  // // Multiplexer - select the spi controller's master
    // among:
    // active flash controller
    // external
  reg_req_t [1:0] spi_host_reg_packet_req;
  reg_rsp_t [1:0] spi_host_reg_packet_rsp;

  assign spi_host_reg_packet_req[0] = spihost_reg_req_i;
  assign spi_host_reg_packet_req[1] = muxed_controllers_reg_req;
  assign muxed_controllers_reg_rsp  = spi_host_reg_packet_rsp[1];
  assign spihost_reg_rsp_o          = spi_host_reg_packet_rsp[0];
 

  reg_req_t spi_host_reg_req_mux;
  reg_rsp_t spi_host_reg_rsp_mux;

  reg_mux #(
      .NoPorts(2),
      .req_t  (reg_req_t),
      .rsp_t  (reg_rsp_t),
      .AW     (AddrWidth),
      .DW     (32)
  ) reg_mux_i (
      .clk_i,
      .rst_ni,
      .in_req_i (spi_host_reg_packet_req),
      .in_rsp_o (spi_host_reg_packet_rsp),
      .out_req_o(spi_host_reg_req_mux),
      .out_rsp_i(spi_host_reg_rsp_mux)
  );


  // OpenTitan SPI Snitch Version used for booting
  spi_host #(
      .reg_req_t(reg_req_t),
      .reg_rsp_t(reg_rsp_t)
  ) ot_spi_i (
      .clk_i,
      .rst_ni,

      // Register interface with master
      .reg_req_i(spi_host_reg_req_mux),
      .reg_rsp_o(spi_host_reg_rsp_mux),
      
      .alert_rx_i(),
      .alert_tx_o(),
      .passthrough_i(spi_device_pkg::PASSTHROUGH_REQ_DEFAULT),
      .passthrough_o(),

      // SPI interface
      .cio_sck_o(ot_spi_sck),
      .cio_sck_en_o(ot_spi_sck_en),
      .cio_csb_o(ot_spi_csb),
      .cio_csb_en_o(ot_spi_csb_en),
      .cio_sd_o(ot_spi_sd_out),
      .cio_sd_en_o(ot_spi_sd_en),
      .cio_sd_i(ot_spi_sd_in),

      .rx_valid_o(ot_spi_rx_valid),
      .tx_ready_o(ot_spi_tx_ready),
      .hw2reg_status_o(external_spi_host_hw2reg_status),
      .intr_error_o(ot_spi_intr_error),
      .intr_spi_event_o(ot_spi_intr_event)
  );

  // Registers
  spi_subsystem_reg_pkg::spi_subsystem_reg2hw_t reg2hw;
  spi_subsystem_reg_pkg::spi_subsystem_hw2reg_t hw2reg;

  spi_subsystem_reg_top #(
      .reg_req_t(reg_req_t),
      .reg_rsp_t(reg_rsp_t)
  ) spi_subsystem_reg_top_i (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .reg_req_i(top_reg_req_i),
      .reg_rsp_o(top_reg_rsp_o),
      .reg2hw,
      .hw2reg,
      .devmode_i(1'b1)
  );


endmodule  // spi_subsystem
