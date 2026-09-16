// Copyright 2026 X-HEEP Contributors
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Top-level module for the X-ALP SoC design.
// Author: Luigi Giuffrida <luigi.giuffrida@polito.it>
//





module x_alp (

    // External Peripheral Interface
    output core_v_mcu_pkg::axi_slv_req_t ext_slv_req_o,
    input  core_v_mcu_pkg::axi_slv_rsp_t ext_slv_rsp_i,

    input  core_v_mcu_pkg::axi_mst_req_t ext_mst_req_i,
    output core_v_mcu_pkg::axi_mst_rsp_t ext_mst_rsp_o,

    output core_v_mcu_pkg::axi_mst_req_t ext_llc_req_o,
    input  core_v_mcu_pkg::axi_mst_rsp_t ext_llc_rsp_i,

    output core_v_mcu_pkg::reg_req_t ext_reg_req_o,
    input  core_v_mcu_pkg::reg_rsp_t ext_reg_rsp_i,

    // Test mode
    input logic test_mode_i,

    // Exit interface
    output logic [31:0] exit_value_o,

    inout wire clk_i,
    inout wire rst_ni,
    inout wire jtag_tck_i,
    inout wire jtag_tms_i,
    inout wire jtag_trst_ni,
    inout wire jtag_tdi_i,
    inout wire jtag_tdo_o,
    inout wire jtag_tdo_oe_o,
    inout wire uart_rx_i,
    inout wire uart_tx_o,
    inout wire exit_valid_o

);

    core_v_mcu u_core_v_mcu (
        .clk_i        (clk_in_x),
        .jtag_tck_i   (jtag_tck_in_x),
        .jtag_tms_i   (jtag_tms_in_x),
        .jtag_trst_ni (jtag_trst_nin_x),
        .jtag_tdi_i   (jtag_tdi_in_x),
        .jtag_tdo_o   (jtag_tdo_out_x),
        .jtag_tdo_oe_o(jtag_tdo_oe_out_x),
        .uart_rx_i    (uart_rx_in_x),
        .uart_tx_o    (uart_tx_out_x),
        .exit_valid_o (exit_valid_out_x),
        .rst_ni       (rst_ngen),
        .boot_select_i(1'b0),
        .exit_value_o (exit_value_o),
        .test_mode_i  (test_mode_i),
        .ext_slv_req_o(ext_slv_req_o),
        .ext_slv_rsp_i(ext_slv_rsp_i),
        .ext_mst_req_i(ext_mst_req_i),
        .ext_mst_rsp_o(ext_mst_rsp_o),
        .ext_reg_req_o(ext_reg_req_o),
        .ext_reg_rsp_i(ext_reg_rsp_i),
        .ext_llc_req_o(ext_llc_req_o),
        .ext_llc_rsp_i(ext_llc_rsp_i)
    );


    pad_ring pad_ring_i (
        .clk_o         (clk_in_x),
        .clk_io        (clk_i),
        .rst_no        (rst_nin_x),
        .rst_nio       (rst_ni),
        .jtag_tck_o    (jtag_tck_in_x),
        .jtag_tck_io   (jtag_tck_i),
        .jtag_tms_o    (jtag_tms_in_x),
        .jtag_tms_io   (jtag_tms_i),
        .jtag_trst_no  (jtag_trst_nin_x),
        .jtag_trst_nio (jtag_trst_ni),
        .jtag_tdi_o    (jtag_tdi_in_x),
        .jtag_tdi_io   (jtag_tdi_i),
        .jtag_tdo_i    (jtag_tdo_out_x),
        .jtag_tdo_io   (jtag_tdo_o),
        .jtag_tdo_oe_i (jtag_tdo_oe_out_x),
        .jtag_tdo_oe_io(jtag_tdo_oe_o),
        .uart_rx_o     (uart_rx_in_x),
        .uart_rx_io    (uart_rx_i),
        .uart_tx_i     (uart_tx_out_x),
        .uart_tx_io    (uart_tx_o),
        .exit_valid_i  (exit_valid_out_x),
        .exit_valid_io (exit_valid_o),


        .pad_attributes_i('0)
    );

    // PAD controller
    core_v_mcu_pkg::reg_req_t pad_req;
    core_v_mcu_pkg::reg_rsp_t pad_resp;


    logic                     rst_ngen;

    // core_v_mcu input/output pins
    logic clk_in_x, clk_out_x, clk_oe_x;
    logic rst_nin_x, rst_nout_x, rst_noe_x;
    logic jtag_tck_in_x, jtag_tck_out_x, jtag_tck_oe_x;
    logic jtag_tms_in_x, jtag_tms_out_x, jtag_tms_oe_x;
    logic jtag_trst_nin_x, jtag_trst_nout_x, jtag_trst_noe_x;
    logic jtag_tdi_in_x, jtag_tdi_out_x, jtag_tdi_oe_x;
    logic jtag_tdo_in_x, jtag_tdo_out_x, jtag_tdo_oe_x;
    logic jtag_tdo_oe_in_x, jtag_tdo_oe_out_x, jtag_tdo_oe_oe_x;
    logic uart_rx_in_x, uart_rx_out_x, uart_rx_oe_x;
    logic uart_tx_in_x, uart_tx_out_x, uart_tx_oe_x;
    logic exit_valid_in_x, exit_valid_out_x, exit_valid_oe_x;


    assign clk_out_x        = 1'b0;
    assign clk_oe_x         = 1'b0;
    assign rst_nout_x       = 1'b0;
    assign rst_noe_x        = 1'b0;
    assign jtag_tck_out_x   = 1'b0;
    assign jtag_tck_oe_x    = 1'b0;
    assign jtag_tms_out_x   = 1'b0;
    assign jtag_tms_oe_x    = 1'b0;
    assign jtag_trst_nout_x = 1'b0;
    assign jtag_trst_noe_x  = 1'b0;
    assign jtag_tdi_out_x   = 1'b0;
    assign jtag_tdi_oe_x    = 1'b0;
    assign jtag_tdo_oe_x    = 1'b1;
    assign jtag_tdo_oe_oe_x = 1'b1;
    assign uart_rx_out_x    = 1'b0;
    assign uart_rx_oe_x     = 1'b0;
    assign uart_tx_oe_x     = 1'b1;
    assign exit_valid_oe_x  = 1'b1;

    // PAD MULTIPLEXERS

    pad_control #(
        .reg_req_t(core_v_mcu_pkg::reg_req_t),
        .reg_rsp_t(core_v_mcu_pkg::reg_rsp_t),
        .NUM_PAD  (core_v_mcu_pkg::NUM_PAD)
    ) pad_control_i (
        .clk_i    (clk_in_x),
        .rst_ni   (rst_ngen),
        .reg_req_i(pad_req),
        .reg_rsp_o(pad_resp)
    );

    rstgen rstgen_i (
        .clk_i      (clk_in_x),
        .rst_ni     (rst_nin_x),
        .test_mode_i(1'b0),
        .rst_no     (rst_ngen),
        .init_no    ()
    );


endmodule : x_alp
