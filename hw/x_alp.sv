// Copyright 2026 X-HEEP Contributors
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Top-level module for the X-ALP SoC design.
// Author: Luigi Giuffrida <luigi.giuffrida@polito.it>
//

module x_alp (

    // Clock and Reset
    input logic clk_i,
    input logic rst_ni,

    output logic uart_tx_o,
    input  logic uart_rx_i,

    output logic        exit_valid_o,
    output logic [31:0] exit_value_o

);

    core_v_mcu u_core_v_mcu (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .boot_select_i(1'b0),
        .exit_valid_o (exit_valid_o),
        .exit_value_o (exit_value_o),
        .uart_rx_i    (uart_rx_i),
        .uart_tx_o    (uart_tx_o)
    );

endmodule : x_alp
