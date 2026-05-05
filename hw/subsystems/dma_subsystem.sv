// DMA SUBSYSTEM
//
// +-------------------------+
// | DMA                     |
// |                         |
// |    +---------------+    |      OBI     +------------------+    AXI
// |    |               |<---|--------------|                  |--->
// |    |   Read unit   |    |              |  obi-axi bridge  |
// |    |               |----|------------->|                  |<---
// |    +---------------+    |              +------------------+
// |                         |
// |                         |
// |    +---------------+    |      OBI     +------------------+    AXI
// |    |               |<---|--------------|                  |--->
// |    |  Write unit   |    |              |  obi-axi bridge  |
// |    |               |----|------------->|                  |<---
// |    +---------------+    |              +------------------+
// |                         |
// |                         |
// |    +---------------+    |      OBI     +------------------+    AXI
// |    |   ADDR MODE   |<---|--------------|                  |--->
// |    | (Read Addr U) |    |              |  obi-axi bridge  |
// |    |               |----|------------->|                  |<---
// |    +---------------+    |              +------------------+
// |                         |
// +-------------------------+

// AXI-Bridged DMA subsystem
`define SLOT_NUM 1
module dma_subsystem (

    // input signals
    input logic clk_i,
    input logic rst_ni,
    input logic clk_gate_en_ni,
    input logic ext_dma_stop_i,

    // Registers
    input  core_v_mcu_pkg::reg_req_t reg_req_i,
    output core_v_mcu_pkg::reg_rsp_t reg_rsp_o,

    // Read unit
    output core_v_mcu_pkg::axi_mst_req_t dma_read_req_o,
    input  core_v_mcu_pkg::axi_mst_rsp_t dma_read_resp_i,

    // Write unit
    output core_v_mcu_pkg::axi_mst_req_t dma_write_req_o,
    input  core_v_mcu_pkg::axi_mst_rsp_t dma_write_resp_i,

    // Address unit
    output core_v_mcu_pkg::axi_mst_req_t dma_addr_req_o,
    input  core_v_mcu_pkg::axi_mst_rsp_t dma_addr_resp_i,

    // FIFO signals
    input  logic                                 hw_fifo_done_i,
    input  fifo_pkg::fifo_resp_t                 hw_fifo_resp_i,
    output fifo_pkg::fifo_req_t                  hw_fifo_req_o,
    input  logic                 [`SLOT_NUM-1:0] trigger_slot_i,

    input dma_reg_pkg::dma_hw2reg_t external_hw2reg_i,

    // output signals
    output logic dma_done_intr_o,
    output logic dma_window_intr_o,

    output logic dma_ready_o,
    output logic dma_done_o

);

    /*  OBI ADAPTER SECTION */
    //  since dma and bridge use 2 different structs

    // signals used from obi used by dma
    obi_xalp_pkg::obi_dma_req_t  obi_dma_read_req;
    obi_xalp_pkg::obi_dma_resp_t obi_dma_read_resp;

    obi_xalp_pkg::obi_dma_req_t  obi_dma_write_req;
    obi_xalp_pkg::obi_dma_resp_t obi_dma_write_resp;

    obi_xalp_pkg::obi_dma_req_t  obi_dma_addr_req;
    obi_xalp_pkg::obi_dma_resp_t obi_dma_addr_resp;


    // signals used from obi by pulp (see include/typedef.svh)
    obi_xalp_pkg::obi_req_t      obi_bridge_read_req;
    obi_xalp_pkg::obi_rsp_t      obi_bridge_read_resp;

    obi_xalp_pkg::obi_req_t      obi_bridge_write_req;
    obi_xalp_pkg::obi_rsp_t      obi_bridge_write_resp;

    obi_xalp_pkg::obi_req_t      obi_bridge_addr_req;
    obi_xalp_pkg::obi_rsp_t      obi_bridge_addr_resp;

    // assignment logic
    assign obi_bridge_read_req.req      = obi_dma_read_req.req;
    assign obi_bridge_read_req.a.addr   = obi_dma_read_req.addr;
    assign obi_bridge_read_req.a.wdata  = obi_dma_read_req.wdata;
    assign obi_bridge_read_req.a.we     = obi_dma_read_req.we;
    assign obi_bridge_read_req.a.be     = obi_dma_read_req.be;

    assign obi_dma_read_resp.gnt        = obi_bridge_read_resp.gnt;
    assign obi_dma_read_resp.rvalid     = obi_bridge_read_resp.rvalid;
    assign obi_dma_read_resp.rdata      = obi_bridge_read_resp.r.rdata;

    assign obi_bridge_write_req.req     = obi_dma_write_req.req;
    assign obi_bridge_write_req.a.addr  = obi_dma_write_req.addr;
    assign obi_bridge_write_req.a.wdata = obi_dma_write_req.wdata;
    assign obi_bridge_write_req.a.we    = obi_dma_write_req.we;
    assign obi_bridge_write_req.a.be    = obi_dma_write_req.be;

    assign obi_dma_write_resp.gnt       = obi_bridge_write_resp.gnt;
    assign obi_dma_write_resp.rvalid    = obi_bridge_write_resp.rvalid;
    assign obi_dma_write_resp.rdata     = obi_bridge_write_resp.r.rdata;

    assign obi_bridge_addr_req.req      = obi_dma_addr_req.req;
    assign obi_bridge_addr_req.a.addr   = obi_dma_addr_req.addr;
    assign obi_bridge_addr_req.a.wdata  = obi_dma_addr_req.wdata;
    assign obi_bridge_addr_req.a.we     = obi_dma_addr_req.we;
    assign obi_bridge_addr_req.a.be     = obi_dma_addr_req.be;

    assign obi_dma_addr_resp.gnt        = obi_bridge_addr_resp.gnt;
    assign obi_dma_addr_resp.rvalid     = obi_bridge_addr_resp.rvalid;
    assign obi_dma_addr_resp.rdata      = obi_bridge_addr_resp.r.rdata;



    // OBI DMA instance
    dma #(
        .FIFO_DEPTH(4),                            // default value in dma.sv
        .SLOT_NUM  (`SLOT_NUM),
        .reg_req_t (core_v_mcu_pkg::reg_req_t),
        .reg_rsp_t (core_v_mcu_pkg::reg_rsp_t),
        .obi_req_t (obi_xalp_pkg::obi_dma_req_t),
        .obi_resp_t(obi_xalp_pkg::obi_dma_resp_t)
    ) u_obi_dma (
        .clk_i,
        .rst_ni,
        .clk_gate_en_ni,

        .ext_dma_stop_i,
        .hw_fifo_done_i,

        .reg_req_i,
        .reg_rsp_o,

        .dma_read_req_o (obi_dma_read_req),  // to bridge
        .dma_read_resp_i(obi_dma_read_resp), // from bridge

        .dma_write_req_o (obi_dma_write_req),
        .dma_write_resp_i(obi_dma_write_resp),

        .dma_addr_req_o (obi_dma_addr_req),
        .dma_addr_resp_i(obi_dma_addr_resp),

        .trigger_slot_i,  // unused


        .hw_fifo_resp_i,
        .hw_fifo_req_o,
        .external_hw2reg_i,

        .dma_done_intr_o,
        .dma_window_intr_o,

        .dma_ready_o,
        .dma_done_o
    );


    // DMA Read Unit bridge
    obi_to_axi #(
        // parameter type definitions
        .obi_req_t   (obi_xalp_pkg::obi_req_t),
        .obi_rsp_t   (obi_xalp_pkg::obi_rsp_t),
        .axi_req_t   (core_v_mcu_pkg::axi_mst_req_t),
        .axi_rsp_t   (core_v_mcu_pkg::axi_mst_rsp_t),
        .AxiAddrWidth(core_v_mcu_pkg::AxiAddrWidth),
        .AxiDataWidth(core_v_mcu_pkg::AxiDataWidth),
        .AxiUserWidth(core_v_mcu_pkg::AxiUserWidth),

        // using axiLite 
        .AxiLite    (1),
        .MaxRequests(1)


    ) dma_read_unit_bridge (
        .clk_i,
        .rst_ni,

        .obi_req_i(obi_bridge_read_req),
        .obi_rsp_o(obi_bridge_read_resp),
        .user_i   (),                      // is not used


        .axi_req_o(dma_read_req_o),
        .axi_rsp_i(dma_read_resp_i),

        .axi_rsp_channel_sel(),
        .axi_rsp_b_user_o   (),
        .axi_rsp_r_user_o   (),

        .obi_rsp_user_i('0)  // tied to 0 since unused
    );


    // DMA Write unit brifdge
    obi_to_axi #(
        // parameter type definitions
        .obi_req_t   (obi_xalp_pkg::obi_req_t),
        .obi_rsp_t   (obi_xalp_pkg::obi_rsp_t),
        .axi_req_t   (core_v_mcu_pkg::axi_mst_req_t),
        .axi_rsp_t   (core_v_mcu_pkg::axi_mst_rsp_t),
        .AxiAddrWidth(core_v_mcu_pkg::AxiAddrWidth),
        .AxiDataWidth(core_v_mcu_pkg::AxiDataWidth),
        .AxiUserWidth(core_v_mcu_pkg::AxiUserWidth),

        // using axiLite 
        .AxiLite    (1),
        .MaxRequests(1)

    ) dma_write_unit_bridge (
        .clk_i,
        .rst_ni,

        .obi_req_i(obi_bridge_write_req),
        .obi_rsp_o(obi_bridge_write_resp),
        .user_i   (),                       // is not used

        .axi_req_o(dma_write_req_o),
        .axi_rsp_i(dma_write_resp_i),

        .axi_rsp_channel_sel(),
        .axi_rsp_b_user_o   (),
        .axi_rsp_r_user_o   (),

        .obi_rsp_user_i('0)  // tied to 0 since unused
    );

    // DMA Addr unit bridge
    obi_to_axi #(
        // parameter type definitions
        .obi_req_t   (obi_xalp_pkg::obi_req_t),
        .obi_rsp_t   (obi_xalp_pkg::obi_rsp_t),
        .axi_req_t   (core_v_mcu_pkg::axi_mst_req_t),
        .axi_rsp_t   (core_v_mcu_pkg::axi_mst_rsp_t),
        .AxiAddrWidth(core_v_mcu_pkg::AxiAddrWidth),
        .AxiDataWidth(core_v_mcu_pkg::AxiDataWidth),
        .AxiUserWidth(core_v_mcu_pkg::AxiUserWidth),

        // using axiLite 
        .AxiLite    (1),
        .MaxRequests(1)

    ) dma_addr_unit_bridge (
        .clk_i,
        .rst_ni,

        .obi_req_i(obi_bridge_addr_req),
        .obi_rsp_o(obi_bridge_addr_resp),
        .user_i   (),                      // is not used

        .axi_req_o(dma_addr_req_o),
        .axi_rsp_i(dma_addr_resp_i),

        .axi_rsp_channel_sel(),
        .axi_rsp_b_user_o   (),
        .axi_rsp_r_user_o   (),
        .obi_rsp_user_i     ('0)  // tied to 0 since unused
    );

endmodule : dma_subsystem
;
