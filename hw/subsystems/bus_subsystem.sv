module bus_subsystem (
    input logic clk_i,
    input logic rst_ni,

    // AXI master
    input  core_v_mcu_pkg::axi_mst_req_t [core_v_mcu_pkg::NumMasters-1:0] axi_master_req_i,
    output core_v_mcu_pkg::axi_mst_rsp_t [core_v_mcu_pkg::NumMasters-1:0] axi_master_resp_o,

    // AXI slave
    output core_v_mcu_pkg::axi_slv_req_t [core_v_mcu_pkg::NumAxiSlaves-1:0] axi_slave_req_o,
    input  core_v_mcu_pkg::axi_slv_rsp_t [core_v_mcu_pkg::NumAxiSlaves-1:0] axi_slave_resp_i,

    // Peripheral register interface
    output core_v_mcu_pkg::reg_req_t  [core_v_mcu_pkg::NumRegSlaves-1:0] reg_req_o,
    input  core_v_mcu_pkg::reg_rsp_t [core_v_mcu_pkg::NumRegSlaves-1:0] reg_rsp_i

);

    // Package import
    import core_v_mcu_pkg::*;

    // Output slaves of the AXI_XBAR is NumAxiSlaves + 1 that goes to the reg bus
    localparam int unsigned NumAxiSlavesInt = NumAxiSlaves;
    localparam int unsigned NumRegSlavesIdx = NumRegSlaves > 1 ? $clog2(NumRegSlaves) : 32'd1;
    // Internal signals
    // ----------------
    axi_slv_req_t  [NumAxiSlavesInt-1:0] axi_slave_req;
    axi_slv_rsp_t [NumAxiSlavesInt-1:0] axi_slave_rsp;
    // AMO <--> CUT
    axi_mst_req_t                       axi_reg_amo_req;
    axi_mst_rsp_t                       axi_reg_amo_rsp;
    // CUT <--> AXI to REG
    axi_mst_req_t                        axi_reg_cut_req;
    axi_mst_rsp_t                       axi_reg_cut_rsp;
    reg_req_t                        reg_in_req;
    reg_rsp_t                       reg_in_rsp;
    // Reg demux 
    logic      [NumRegSlavesIdx-1:0] reg_select;

    // AXI XBAR
    //---------
    axi_xbar #(
        .Cfg          (AxiXbarCfg),
        .ATOPs        (1),
        .Connectivity ('1),
        .slv_aw_chan_t(axi_mst_aw_chan_t),
        .mst_aw_chan_t(axi_slv_aw_chan_t),
        .w_chan_t     (axi_mst_w_chan_t),
        .slv_b_chan_t (axi_mst_b_chan_t),
        .mst_b_chan_t (axi_slv_b_chan_t),
        .slv_ar_chan_t(axi_mst_ar_chan_t),
        .mst_ar_chan_t(axi_slv_ar_chan_t),
        .slv_r_chan_t (axi_mst_r_chan_t),
        .mst_r_chan_t (axi_slv_r_chan_t),
        .slv_req_t    (axi_mst_req_t),
        .slv_resp_t   (axi_mst_rsp_t),
        .mst_req_t    (axi_slv_req_t),
        .mst_resp_t   (axi_slv_rsp_t),
        .rule_t       (rule_t)
    ) i_axi_xbar (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .test_i               ('0),
        .slv_ports_req_i      (axi_master_req_i),
        .slv_ports_resp_o     (axi_master_resp_o),
        .mst_ports_req_o      (axi_slave_req),
        .mst_ports_resp_i     (axi_slave_rsp),
        .addr_map_i           (addr_rules),
        .en_default_mst_port_i('0),
        .default_mst_port_i   ('0)
    );

    //-------------------
    // Reg Peripheral Bus
    //-------------------

    // Atomics
    //--------
    axi_riscv_atomics_structs #(
        .AxiAddrWidth   (AxiAddrWidth),
        .AxiDataWidth   (AxiDataWidth),
        .AxiIdWidth     (AxiSlvIdWidth),
        .AxiUserWidth   (AxiUserWidth),
        .AxiMaxReadTxns (1),
        .AxiMaxWriteTxns(1),
        .AxiUserAsId    (0),
        .AxiUserIdMsb   (0),
        .AxiUserIdLsb   (0),
        .RiscvWordWidth (64),
        .NAxiCuts       (1),
        .axi_req_t      (axi_slv_req_t),
        .axi_rsp_t      (axi_slv_rsp_t)
    ) i_reg_atomics (
        .clk_i,
        .rst_ni,
        .axi_slv_req_i(axi_slave_req[0]),   // TODO: can replace with param in pkg
        .axi_slv_rsp_o(axi_slave_rsp[0]),  // TODO: can replace with param in pkg
        .axi_mst_req_o(axi_reg_amo_req),
        .axi_mst_rsp_i(axi_reg_amo_rsp)
    );

    axi_cut #(
        .Bypass    (~1),             // TODO: missing params
        .aw_chan_t (axi_mst_aw_chan_t),
        .w_chan_t  (axi_mst_w_chan_t),
        .b_chan_t  (axi_mst_b_chan_t),
        .ar_chan_t (axi_mst_ar_chan_t),
        .r_chan_t  (axi_mst_r_chan_t),
        .axi_req_t (axi_mst_req_t),
        .axi_resp_t(axi_mst_rsp_t)
    ) i_reg_atomics_cut (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .slv_req_i (axi_reg_amo_req),
        .slv_resp_o(axi_reg_amo_rsp),
        .mst_req_o (axi_reg_cut_req),
        .mst_resp_i(axi_reg_cut_rsp)
    );

    // Convert from AXI to reg protocol
    axi_to_reg_v2 #(
        .AxiAddrWidth(AxiAddrWidth),
        .AxiDataWidth(AxiDataWidth),
        .AxiIdWidth  (AxiSlvIdWidth),
        .AxiUserWidth(AxiUserWidth),
        .RegDataWidth(32),
        .CutMemReqs  (0),
        .axi_req_t   (axi_mst_req_t),
        .axi_rsp_t   (axi_mst_rsp_t),
        .reg_req_t   (reg_req_t),
        .reg_rsp_t   (reg_rsp_t)
    ) i_axi_to_reg_v2 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .axi_req_i(axi_reg_cut_req),
        .axi_rsp_o(axi_reg_cut_rsp),
        .reg_req_o(reg_in_req),
        .reg_rsp_i(reg_in_rsp),
        .reg_id_o (),
        .busy_o   ()
    );

    // Non-matching addresses are directed to an error slave
    addr_decode #(
        .NoIndices(NumRegSlaves),
        .NoRules  (NumRegSlaves),
        .addr_t   (addr_t),
        .rule_t   (rule_t)
    ) i_reg_demux_decode (
        .addr_i          (reg_in_req.addr),
        .addr_map_i      (RegMap),
        .idx_o           (reg_select),
        .dec_valid_o     (),
        .dec_error_o     (),
        .en_default_idx_i(1'b1),
        .default_idx_i   ('0)
    );

    reg_demux #(
        .NoPorts(NumRegSlaves),
        .req_t  (reg_req_t),
        .rsp_t  (reg_rsp_t)
    ) u_reg_demux (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .in_select_i(reg_select),
        .in_req_i   (reg_in_req),
        .in_rsp_o   (reg_in_rsp),
        .out_req_o  (reg_req_o),
        .out_rsp_i  (reg_rsp_i)
    );


    assign axi_slave_req_o               = axi_slave_req[NumAxiSlaves:1];
    assign axi_slave_rsp[NumAxiSlaves:1] = axi_slave_resp_i;


endmodule
