// Copyright 2026 X-HEEP Contributors
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Top-level module for the Core-V MCU design.
// Author: Luigi Giuffrida <luigi.giuffrida@polito.it>
//

module core_v_mcu (

    input logic clk_i,
    input logic rst_ni,

    // UART IO
    input  logic uart_rx_i,
    output logic uart_tx_o,

    // Boot select
    input logic boot_select_i,

    // JTAG Interface
    input  logic jtag_tck_i,
    input  logic jtag_tms_i,
    input  logic jtag_trst_ni,
    input  logic jtag_tdi_i,
    output logic jtag_tdo_o,
    output logic jtag_tdo_oe_o,

    // Test mode
    input logic test_mode_i,

    // Exit interface
    output logic        exit_valid_o,
    output logic [31:0] exit_value_o

);

    /* verilator lint_off PINCONNECTEMPTY */
    /* verilator lint_off PINMISSING      */

    import core_v_mcu_pkg::*;

    // Internal signals
    core_v_mcu_pkg::axi_mst_req_t [NumAxiMasters-1:0] axi_master_req_sig;
    core_v_mcu_pkg::axi_mst_rsp_t [NumAxiMasters-1:0] axi_master_rsp_sig;
    core_v_mcu_pkg::axi_slv_req_t [ NumAxiSlaves-1:0] axi_slave_req_sig;
    core_v_mcu_pkg::axi_slv_rsp_t [ NumAxiSlaves-1:0] axi_slave_rsp_sig;

    core_v_mcu_pkg::reg_req_t     [ NumRegSlaves-1:0] reg_req_sig;
    core_v_mcu_pkg::reg_rsp_t     [ NumRegSlaves-1:0] reg_rsp_sig;

    logic                         [             15:0] fast_intr;
    logic                         [             15:0] fast_irq;

    logic                                             debug_req;

    //
    //       █████████  ███████████  █████  █████
    //      ███░░░░░███░░███░░░░░███░░███  ░░███ 
    //     ███     ░░░  ░███    ░███ ░███   ░███ 
    //    ░███          ░██████████  ░███   ░███ 
    //    ░███          ░███░░░░░░   ░███   ░███ 
    //    ░░███     ███ ░███         ░███   ░███ 
    //     ░░█████████  █████        ░░████████  
    //      ░░░░░░░░░  ░░░░░          ░░░░░░░░   
    //

    cpu_subsystem u_cpu_subsystem (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .boot_addr_i(core_v_mcu_pkg::BOOT_ADDR),

        // .cvxif_resp_o (),
        // .cvxif_req_i('0),

        .bus_req_o(axi_master_req_sig[CPU_BUS_IDX]),
        .bus_rsp_i(axi_master_rsp_sig[CPU_BUS_IDX]),

        .irq_i      (fast_irq[1:0]),
        .time_irq_i ('0),
        .debug_req_i(debug_req)
    );

    // 
    //  ██████   ██████                                                        
    // ░░██████ ██████                                                         
    //  ░███░█████░███   ██████  █████████████    ██████  ████████  █████ ████ 
    //  ░███░░███ ░███  ███░░███░░███░░███░░███  ███░░███░░███░░███░░███ ░███  
    //  ░███ ░░░  ░███ ░███████  ░███ ░███ ░███ ░███ ░███ ░███ ░░░  ░███ ░███  
    //  ░███      ░███ ░███░░░   ░███ ░███ ░███ ░███ ░███ ░███      ░███ ░███  
    //  █████     █████░░██████  █████░███ █████░░██████  █████     ░░███████  
    // ░░░░░     ░░░░░  ░░░░░░  ░░░░░ ░░░ ░░░░░  ░░░░░░  ░░░░░       ░░░░░███  
    //                                                               ███ ░███  
    //                                                              ░░██████   
    //                                                               ░░░░░░    
    // 

    memory_subsystem u_memory_subsystem (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .bus_req_i(axi_slave_req_sig[MEM_BUS_IDX]),
        .bus_rsp_o(axi_slave_rsp_sig[MEM_BUS_IDX])
    );

    //
    //  ███████████  █████  █████  █████████ 
    // ░░███░░░░░███░░███  ░░███  ███░░░░░███
    //  ░███    ░███ ░███   ░███ ░███    ░░░ 
    //  ░██████████  ░███   ░███ ░░█████████ 
    //  ░███░░░░░███ ░███   ░███  ░░░░░░░░███
    //  ░███    ░███ ░███   ░███  ███    ░███
    //  ███████████  ░░████████  ░░█████████ 
    // ░░░░░░░░░░░    ░░░░░░░░    ░░░░░░░░░  
    //                                  

    bus_subsystem u_bus_subsystem (
        .clk_i (clk_i),
        .rst_ni(rst_ni),

        // AXI master
        .axi_master_req_i(axi_master_req_sig),
        .axi_master_rsp_o(axi_master_rsp_sig),

        // AXI slave
        .axi_slave_req_o(axi_slave_req_sig),
        .axi_slave_rsp_i(axi_slave_rsp_sig),

        // Peripheral register interface
        .reg_req_o(reg_req_sig),
        .reg_rsp_i(reg_rsp_sig)
    );

    // 
    //  ███████████                      ███            █████                                   ████         
    // ░░███░░░░░███                    ░░░            ░░███                                   ░░███         
    //  ░███    ░███  ██████  ████████  ████  ████████  ░███████    ██████  ████████   ██████   ░███   █████ 
    //  ░██████████  ███░░███░░███░░███░░███ ░░███░░███ ░███░░███  ███░░███░░███░░███ ░░░░░███  ░███  ███░░  
    //  ░███░░░░░░  ░███████  ░███ ░░░  ░███  ░███ ░███ ░███ ░███ ░███████  ░███ ░░░   ███████  ░███ ░░█████ 
    //  ░███        ░███░░░   ░███      ░███  ░███ ░███ ░███ ░███ ░███░░░   ░███      ███░░███  ░███  ░░░░███
    //  █████       ░░██████  █████     █████ ░███████  ████ █████░░██████  █████    ░░████████ █████ ██████ 
    // ░░░░░         ░░░░░░  ░░░░░     ░░░░░  ░███░░░  ░░░░ ░░░░░  ░░░░░░  ░░░░░      ░░░░░░░░ ░░░░░ ░░░░░░  
    //                                        ░███                                                           
    //                                        █████                                                          
    //                                       ░░░░░                                                           
    // 

    soc_ctrl #(
        .reg_req_t(core_v_mcu_pkg::reg_req_t),
        .reg_rsp_t(core_v_mcu_pkg::reg_rsp_t)
    ) u_soc_ctrl (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .reg_req_i    (reg_req_sig[SOC_CTRL_REG_IDX]),
        .reg_rsp_o    (reg_rsp_sig[SOC_CTRL_REG_IDX]),
        .boot_select_i(boot_select_i),
        .exit_valid_o (exit_valid_o),
        .exit_value_o (exit_value_o)
    );

    bootrom_subsystem #(
        .reg_req_t(core_v_mcu_pkg::reg_req_t),
        .reg_rsp_t(core_v_mcu_pkg::reg_rsp_t)
    ) u_bootrom_subsystem (
        .reg_req_i(reg_req_sig[BOOT_ROM_REG_IDX]),
        .reg_rsp_o(reg_rsp_sig[BOOT_ROM_REG_IDX])
    );

    assign fast_intr = '0;  // No external fast interrupts for now

    fast_intr_ctrl #(
        .reg_req_t(core_v_mcu_pkg::reg_req_t),
        .reg_rsp_t(core_v_mcu_pkg::reg_rsp_t)
    ) u_fast_intr_ctrl (
        .clk_i (clk_i),
        .rst_ni(rst_ni),

        // Bus Interface
        .reg_req_i(reg_req_sig[FAST_INTR_CTRL_REG_IDX]),
        .reg_rsp_o(reg_rsp_sig[FAST_INTR_CTRL_REG_IDX]),

        .fast_intr_i(fast_intr),
        .fast_intr_o(fast_irq)
    );

    uart_subsystem u_uart_subsystem (
        .clk_i                    (clk_i),
        .rst_ni                   (rst_ni),
        .uart_reg_req             (reg_req_sig[UART_REG_IDX]),
        .uart_reg_rsp             (reg_rsp_sig[UART_REG_IDX]),
        .uart_rx_i                (uart_rx_i),
        .uart_tx_o                (uart_tx_o),
        .uart_intr_tx_watermark_o (),
        .uart_intr_rx_watermark_o (),
        .uart_intr_tx_empty_o     (),
        .uart_intr_rx_overflow_o  (),
        .uart_intr_rx_frame_err_o (),
        .uart_intr_rx_break_err_o (),
        .uart_intr_rx_timeout_o   (),
        .uart_intr_rx_parity_err_o()
    );

    debug_subsystem u_debug_subsystem (
        .clk_i (clk_i),
        .rst_ni(rst_ni),

        // AXI Slave Interface
        .axi_slv_req_i(axi_slave_req_sig[DEBUG_S_BUS_IDX]),
        .axi_slv_rsp_o(axi_slave_rsp_sig[DEBUG_S_BUS_IDX]),

        // AXI Master Interface
        .axi_mst_req_o(axi_master_req_sig[DEBUG_M_BUS_IDX]),
        .axi_mst_rsp_i(axi_master_rsp_sig[DEBUG_M_BUS_IDX]),
        // JTAG Interface
        .jtag_tck_i   (jtag_tck_i),
        .jtag_tms_i   (jtag_tms_i),
        .jtag_trst_ni (jtag_trst_ni),
        .jtag_tdi_i   (jtag_tdi_i),
        .jtag_tdo_o   (jtag_tdo_o),
        .jtag_tdo_oe_o(jtag_tdo_oe_o),
        // Test mode
        .test_mode_i  (test_mode_i),
        // Debug signals
        .dbg_active_o (),
        .dbg_req_o    (debug_req)

    );

endmodule
