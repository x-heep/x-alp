// Copyright 2022 EPFL
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1




module pad_control #(
    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic,
        /* verilator lint_off UNUSED */
    parameter NUM_PAD = 1
) (

        /* verilator lint_off UNUSED */
    input logic clk_i,
        /* verilator lint_off UNUSED */
    input logic rst_ni,

    // Bus Interface
        /* verilator lint_off UNUSED */
    input  reg_req_t reg_req_i,
        /* verilator lint_off UNDRIVEN */
    output reg_rsp_t reg_rsp_o
);




endmodule : pad_control
