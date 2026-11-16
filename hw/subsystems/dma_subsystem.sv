
//import core_v_mcu_pkg::*;
module dma_subsystem (
    input logic clk_i,
    input logic rst_ni,


    // // Peripheral register interface
    // .dma_reg_req_i(reg_req_sig[DMA_REG_IDX]),
    // .dma_reg_rsp_o(reg_rsp_sig[DMA_REG_IDX]),

    // //AXI R Master
    // .bus_req_o(axi_master_req_sig[DMA_R_M_BUS_IDX]),
    // .bus_rsp_i(axi_master_rsp_sig[DMA_R_M_BUS_IDX]),

    // //AXI W Master
    // .bus_req_o(axi_master_req_sig[DMA_W_M_BUS_IDX]),
    // .bus_rsp_i(axi_master_rsp_sig[DMA_W_M_BUS_IDX])

    input  core_v_mcu_pkg::reg_req_t dma_reg_req_i,
    output core_v_mcu_pkg::reg_rsp_t dma_reg_rsp_o,

    // AXI bus Request Master Read
    output core_v_mcu_pkg::axi_mst_req_t bus_req_o_r,  //this is a master!
    // AXI bus response Master Read
    input  core_v_mcu_pkg::axi_mst_rsp_t bus_rsp_i_r,

    output core_v_mcu_pkg::axi_mst_req_t bus_req_o_w,  //
    input  core_v_mcu_pkg::axi_mst_rsp_t bus_rsp_i_w




    /* verilator lint_off PINCONNECTEMPTY */
    /* verilator lint_off PINMISSING      */

);


endmodule
;
