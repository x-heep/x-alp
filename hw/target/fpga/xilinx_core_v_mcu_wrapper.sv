// Copyright 2026 X-HEEP Contributors
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Top-level module for the X-ALP SoC FPGA wrapper.
// Author: Christian Conti, Luigi Giuffrida <{christian.conti, luigi.giuffrida}@polito.it>
//


module xilinx_core_v_mcu_wrapper #(
    parameter CLK_LED_COUNT_LENGTH = 27
) (

`ifdef FPGA_AUP_ZU3
    inout logic clk_100mhz_n,
    inout logic clk_100mhz_p,
`else
    inout logic clk_i,
`endif

    inout logic rst_i,

    output logic rst_led_o,
    output logic clk_led_o,

    inout logic jtag_tck_i,
    inout logic jtag_tms_i,
    inout logic jtag_trst_ni,
    inout logic jtag_tdi_i,
    inout logic jtag_tdo_o,

    inout logic uart_rx_i,
    inout logic uart_tx_o,

    output logic exit_value_o,
    inout  logic exit_valid_o
);

    wire                               clk_gen;
    logic [                      31:0] exit_value;
    wire                               rst_n;
    logic [CLK_LED_COUNT_LENGTH - 1:0] clk_count;

    // low active reset
    // `ifdef FPGA_XXXX
    //  assign rst_n = rst_i;
    // `elsif FPGA_YYYY
    //  assign rst_n = rst_i;
    // `else
    assign rst_n     = !rst_i;
    // `endif

    // reset LED for debugging
    assign rst_led_o = rst_n;

    // counter to blink an LED
    assign clk_led_o = clk_count[CLK_LED_COUNT_LENGTH-1];

    always_ff @(posedge clk_gen or negedge rst_n) begin : clk_count_process
        if (!rst_n) begin
            clk_count <= '0;
        end else begin
            clk_count <= clk_count + 1;
        end
    end

    // `ifdef FPGA_XXXX
    //   xilinx_clk_wizard_wrapper xilinx_clk_wizard_wrapper_i (
    //       .clk_125MHz(clk_i),
    //       .clk_out1_0(clk_gen)
    //   );
    // `elsif FPGA_YYYY
    //   xilinx_clk_wizard_wrapper xilinx_clk_wizard_wrapper_i (
    //       .CLK_IN1_D_0_clk_n(clk_200mhz_n),
    //       .CLK_IN1_D_0_clk_p(clk_200mhz_p),
    //       .clk_out1_0(clk_gen)
    //   );
    // `else  // FPGA AUP-ZU3
    xilinx_clk_wizard_wrapper xilinx_clk_wizard_wrapper_i (
        .CLK_IN1_D_0_clk_n(clk_100mhz_n),
        .CLK_IN1_D_0_clk_p(clk_100mhz_p),
        .clk_out1_0       (clk_gen)
    );
    // `endif

    x_alp x_alp_system_i (
        .clk_i (clk_gen),
        .rst_ni(rst_n),

        .jtag_tck_i  (jtag_tck_i),
        .jtag_tms_i  (jtag_tms_i),
        .jtag_trst_ni(jtag_trst_ni),
        .jtag_tdi_i  (jtag_tdi_i),
        .jtag_tdo_o  (jtag_tdo_o),

        .uart_rx_i   (uart_rx_i),
        .uart_tx_o   (uart_tx_o),
        .exit_valid_o(exit_valid_o),
        .exit_value_o(exit_value),

        .test_mode_i(1'b0)
    );

    assign exit_value_o = exit_value[0];

endmodule
