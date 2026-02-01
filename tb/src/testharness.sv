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
// File: x_alp_testharness.sv
// Author: Flavia Guella
// Date: 03/12/2025
// Inspired by x-heep testharness.sv

module testharness #(
    parameter int unsigned CLK_FREQUENCY = 'd100_000  //KHz
) (
    input logic clk_i,
    input logic rst_ni,

    // Boot mode
    //----------
    input logic [1:0] boot_mode_i,

    // RTC Clic clock
    // --------------
    input logic rtc_i,

    // JTAG
    // ----
    input  logic jtag_tck_i,
    input  logic jtag_tms_i,
    input  logic jtag_trst_ni,
    input  logic jtag_tdi_i,
    output logic jtag_tdo_o,

    // Exit sim
    // --------
    output logic [31:0] exit_value_o,
    output logic        exit_valid_o
);

    // Includes
    // --------
    `include "tb_util.svh"

    // Internal signals
    // ----------------

    // JTAG
    logic                         sim_jtag_enable;
    logic                         sim_jtag_tck;
    logic                         sim_jtag_trst_n;
    logic                         sim_jtag_tms;
    logic                         sim_jtag_tdi;
    logic                         sim_jtag_tdo;

    logic                         jtag_tck;
    logic                         jtag_trst_n;
    logic                         jtag_tms;
    logic                         jtag_tdi;
    logic                         jtag_tdo;

    // UART
    logic                         uart_tx;
    logic                         uart_rx;

    // External Peripheral Interface
    core_v_mcu_pkg::axi_slv_req_t ext_slv_req;
    core_v_mcu_pkg::axi_slv_rsp_t ext_slv_rsp;

    // Memory interface
    localparam int AddrWidth = $clog2(256) + 1;
    logic                 tb_mem_req;
    logic [AddrWidth-1:0] tb_mem_addr;
    logic [         63:0] tb_mem_wdata;
    logic                 tb_mem_we;
    logic [         63:0] tb_mem_rdata;


    //----
    // DUT
    //----
    x_alp u_x_alp (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .uart_tx_o    (uart_tx),
        .uart_rx_i    (uart_rx),
        .exit_valid_o (exit_valid_o),
        .exit_value_o (exit_value_o),
        .jtag_tck_i   (jtag_tck),
        .jtag_tms_i   (jtag_tms),
        .jtag_trst_ni (jtag_trst_n),
        .jtag_tdi_i   (jtag_tdi),
        .jtag_tdo_o   (jtag_tdo),
        .jtag_tdo_oe_o(),
        .ext_slv_req_o(ext_slv_req),
        .ext_slv_rsp_i(ext_slv_rsp),
        .ext_mst_req_i(),
        .ext_mst_rsp_o(),
        .ext_reg_req_o(),
        .ext_reg_rsp_i(),
        .test_mode_i  (1'b0)
    );

    // --------

    axi_to_mem #(
        .axi_req_t   (core_v_mcu_pkg::axi_slv_req_t),
        .axi_resp_t  (core_v_mcu_pkg::axi_slv_rsp_t),
        .AddrWidth   (AddrWidth),
        .DataWidth   (64),
        .NumBanks    (1),
        .BufDepth    (1),
        .HideStrb    (0),
        .OutFifoDepth(1)
    ) u_tb_axi_to_mem (
        .clk_i       (clk_i),
        .rst_ni      (rst_ni),
        .busy_o      (),
        .axi_req_i   (ext_slv_req),
        .axi_resp_o  (ext_slv_rsp),
        .mem_req_o   (tb_mem_req),
        .mem_gnt_i   (tb_mem_req),
        .mem_addr_o  (tb_mem_addr),
        .mem_wdata_o (tb_mem_wdata),
        .mem_strb_o  (),
        .mem_atop_o  (),
        .mem_we_o    (tb_mem_we),
        .mem_rvalid_i(tb_mem_valid),
        .mem_rdata_i (tb_mem_rdata)
    );

    logic tb_mem_valid_q;
    logic tb_mem_valid;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            tb_mem_valid_q <= '0;
        end else begin
            tb_mem_valid_q <= tb_mem_req;
        end
    end

    assign tb_mem_valid = tb_mem_valid_q;

    sram_wrapper #(
        .NumWords (256),
        .DataWidth(64)
    ) u_tb_ram0 (
        .clk_i           (clk_i),
        .rst_ni          (rst_ni),
        .req_i           (tb_mem_req),
        .we_i            (tb_mem_we),
        .addr_i          ({2'b00, tb_mem_addr[AddrWidth-1:3]}),
        .wdata_i         (tb_mem_wdata),
        .be_i            ('1),
        .pwrgate_ni      ('1),
        .pwrgate_ack_no  (),
        .set_retentive_ni('1),
        .rdata_o         (tb_mem_rdata)
    );



    // --------
    // UART DPI
    // --------

    uartdpi #(
        .BAUD('d256000),
        .FREQ(CLK_FREQUENCY * 1000),  //Hz
        .NAME("uart0")
    ) i_uart0 (
        .clk_i (clk_i),
        .rst_ni(rst_ni),
        .tx_o  (uart_rx),
        .rx_i  (uart_tx)
    );

endmodule

