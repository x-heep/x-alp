//
// Power Manager Subsystem module.
// Author: Jyotiraditya Satpathy <s353517@studenti.polito.it>
//

module power_manager_subsystem 
import power_manager_pkg::*; #(         // Importing here to use package ports
    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic
) (
    input logic clk_i,
    input logic rst_ni,

    // Bus Interface
    input reg_req_t reg_req_i,
    output reg_rsp_t reg_rsp_o,

    // Status Signal
    input logic core_sleep_i,

    // Input Interrupt Array
    input logic [31:0] intr_i,

    // External Interrupts
    input logic [core_v_mini_mcu_pkg::NEXT_INT == 0 ? 1 : core_v_mini_mcu_pkg::NEXT_INT-1:0] ext_irq_i,

    // Power Manager Output Signals
    output power_manager_out_t cpu_subsystem_pwr_ctrl_o,
    output power_manager_out_t peripheral_subsystem_pwr_ctrl_o,
    output power_manager_out_t memory_subsystem_pwr_ctrl_o[core_v_mini_mcu_pkg::NUM_BANKS-1:0],
    output power_manager_out_t external_subsystem_pwr_ctrl_o[core_v_mini_mcu_pkg::EXTERNAL_DOMAINS == 0 ? 1 : core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0],
    output power_manager_out_t dma_subsystem_pwr_ctrl_o[core_v_mini_mcu_pkg::DMA_CH_NUM-1:0],

    // Power Manager Input Signals
    input power_manager_in_t cpu_subsystem_pwr_ctrl_i,
    input power_manager_in_t peripheral_subsystem_pwr_ctrl_i,
    input power_manager_in_t memory_subsystem_pwr_ctrl_i[core_v_mini_mcu_pkg::NUM_BANKS-1:0],
    input power_manager_in_t external_subsystem_pwr_ctrl_i[core_v_mini_mcu_pkg::EXTERNAL_DOMAINS == 0 ? 1 : core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0]
);

    power_manager #(
        .reg_req_t(reg_req_t),
        .reg_rsp_t(reg_rsp_t)
    ) u_power_manager (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),

        .reg_req_i  (reg_req_i),
        .reg_rsp_o  (reg_rsp_o),

        .core_sleep_i   (core_sleep_i),
        .intr_i         (intr_i),
        .ext_irq_i      (ext_irq_i),

        .cpu_subsystem_pwr_ctrl_o           (cpu_subsystem_pwr_ctrl_o),
        .peripheral_subsystem_pwr_ctrl_o    (peripheral_subsystem_pwr_ctrl_o),
        .memory_subsystem_pwr_ctrl_o        (memory_subsystem_pwr_ctrl_o),
        .external_subsystem_pwr_ctrl_o      (external_subsystem_pwr_ctrl_o),
        .dma_subsystem_pwr_ctrl_o           (dma_subsystem_pwr_ctrl_o),

        .cpu_subsystem_pwr_ctrl_i           (cpu_subsystem_pwr_ctrl_i),
        .peripheral_subsystem_pwr_ctrl_i    (peripheral_subsystem_pwr_ctrl_i),
        .memory_subsystem_pwr_ctrl_i        (memory_subsystem_pwr_ctrl_i),
        .external_subsystem_pwr_ctrl_i      (external_subsystem_pwr_ctrl_i)
    );

endmodule : power_manager_subsystem