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
    // logic sim_jtag_enable;
    // logic sim_jtag_tck;
    // logic sim_jtag_trst_n;
    // logic sim_jtag_tms;
    // logic sim_jtag_tdi;
    // logic sim_jtag_tdo;

    logic jtag_tck;
    logic jtag_trst_n;
    logic jtag_tms;
    logic jtag_tdi;
    logic jtag_tdo;

    // UART
    logic uart_tx;
    logic uart_rx;


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
        .test_mode_i  (1'b0)
    );

    uartdpi #(
        .BAUD('d256000),
        .FREQ(CLK_FREQUENCY * 1000),  //Hz
        .NAME("uart0")
    ) u_uart0 (
        .clk_i (clk_i),
        .rst_ni(rst_ni),
        .tx_o  (uart_rx),
        .rx_i  (uart_tx)
    );

    SimJTAG #(
        .TICK_DELAY(1),
        .PORT      (4567)
    ) u_sim_jtag (
        .clock          (clk_i),
        .reset          (~rst_ni),
        .enable         (1'b1),
        .init_done      (rst_ni),
        .jtag_TCK       (jtag_tck),
        .jtag_TMS       (jtag_tms),
        .jtag_TDI       (jtag_tdi),
        .jtag_TRSTn     (jtag_trst_n),
        .jtag_TDO_data  (jtag_tdo),
        .jtag_TDO_driven(1'b1),
        .exit           ()
    );

endmodule

