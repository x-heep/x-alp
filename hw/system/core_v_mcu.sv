module core_v_mcu (

    input logic clk_i,
    input logic rst_ni,

    // UART IO
    input  logic uart_rx_i,
    output logic uart_tx_o,

    // Boot select
    input logic boot_select_i,

    // Exit interface
    output logic        exit_valid_o,
    output logic [31:0] exit_value_o

);

    /* verilator lint_off PINCONNECTEMPTY */
    /* verilator lint_off PINMISSING      */

    import core_v_mcu_pkg::*;

    // Internal signals
    core_v_mcu_pkg::axi_mst_req_t  [  NumMasters-1:0] axi_master_req_sig;
    core_v_mcu_pkg::axi_mst_rsp_t [  NumMasters-1:0] axi_master_resp_sig;
    core_v_mcu_pkg::axi_slv_req_t  [   NumAxiSlaves-1:0] axi_slave_req_sig;
    core_v_mcu_pkg::axi_slv_rsp_t [   NumAxiSlaves-1:0] axi_slave_resp_sig;

    core_v_mcu_pkg::reg_req_t  [NumRegSlaves-1:0] reg_req_sig;
    core_v_mcu_pkg::reg_rsp_t [NumRegSlaves-1:0] reg_resp_sig;

    logic                          [            15:0] fast_intr;
    logic                          [            15:0] fast_irq;

    // CPU Subsystem
    cpu_subsystem u_cpu_subsystem (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .boot_addr_i(64'h0000_0000_0000_0180),

        // .cvxif_resp_o (),
        // .cvxif_req_i('0),

        .bus_req_o (axi_master_req_sig[CPU_BUS_IDX]),
        .bus_resp_i(axi_master_resp_sig[CPU_BUS_IDX]),

        .irq_i      (fast_irq[1:0]),
        .time_irq_i ('0),
        .debug_req_i('0)
    );

    // Memory Subsystem
    memory_subsystem u_memory_subsystem (
        .clk_i     (clk_i),
        .rst_ni    (rst_ni),
        .bus_req_i (axi_slave_req_sig[MEM_BUS_IDX]),
        .bus_resp_o(axi_slave_resp_sig[MEM_BUS_IDX])
    );

    // Bus Subsystem
    bus_subsystem u_bus_subsystem (
        .clk_i (clk_i),
        .rst_ni(rst_ni),

        // AXI master
        .axi_master_req_i (axi_master_req_sig),
        .axi_master_resp_o(axi_master_resp_sig),

        // AXI slave
        .axi_slave_req_o (axi_slave_req_sig),
        .axi_slave_resp_i(axi_slave_resp_sig),

        // Peripheral register interface
        .reg_req_o (reg_req_sig),
        .reg_rsp_i(reg_resp_sig)
    );

    // Peripherals

    // SoC Controller

    soc_ctrl #(
        .reg_req_t(core_v_mcu_reg_pkg::reg_req_t),
        .reg_rsp_t(core_v_mcu_reg_pkg::reg_resp_t)
    ) soc_ctrl_i (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .reg_req_i    (reg_req_sig[SOC_CTRL_REG_IDX]),
        .reg_rsp_o    (reg_resp_sig[SOC_CTRL_REG_IDX]),
        .boot_select_i(boot_select_i),
        .exit_valid_o (exit_valid_o),
        .exit_value_o (exit_value_o)
    );

    // Fast Interrupt Controller

    assign fast_intr = '0;  // No external fast interrupts for now

    fast_intr_ctrl #(
        .reg_req_t(core_v_mcu_reg_pkg::reg_req_t),
        .reg_rsp_t(core_v_mcu_reg_pkg::reg_resp_t)
    ) u_fast_intr_ctrl (
        .clk_i (clk_i),
        .rst_ni(rst_ni),

        // Bus Interface
        .reg_req_i(reg_req_sig[FAST_INTR_CTRL_REG_IDX]),
        .reg_rsp_o(reg_resp_sig[FAST_INTR_CTRL_REG_IDX]),

        .fast_intr_i(fast_intr),
        .fast_intr_o(fast_irq)
    );

    // UART Subsystem

    uart_subsystem u_uart_subsystem (
        .clk_i                    (clk_i),
        .rst_ni                   (rst_ni),
        .uart_reg_req             (reg_req_sig[UART_REG_IDX]),
        .uart_reg_rsp             (reg_resp_sig[UART_REG_IDX]),
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


endmodule
