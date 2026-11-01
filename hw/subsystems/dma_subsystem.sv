module dma_subsystem (
    input logic clk_i,
    input logic rst_ni,

    // AXI bus request
    output core_v_mcu_pkg::axi_mst_req_t bus_req_o, //this is a master!
    // AXI bus response
    input  core_v_mcu_pkg::axi_mst_rsp_t bus_rsp_i
    
    /* verilator lint_off PINCONNECTEMPTY */
    /* verilator lint_off PINMISSING      */

);
    import core_v_mcu_pkg::*;

endmodule;
