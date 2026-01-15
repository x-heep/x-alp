module bus_subsystem (
    input logic clk_i,
    input logic rst_ni,

    // AXI master
    input  core_v_mcu_axi_pkg::axi_req_t  [core_v_mcu_pkg::NumMasters-1:0] axi_master_req_i,
    output core_v_mcu_axi_pkg::axi_resp_t [core_v_mcu_pkg::NumMasters-1:0] axi_master_resp_o,

    // AXI slave
    output core_v_mcu_axi_pkg::axi_req_t  [core_v_mcu_pkg::NumAxiSlaves-1:0] axi_slave_req_o,
    input  core_v_mcu_axi_pkg::axi_resp_t [core_v_mcu_pkg::NumAxiSlaves-1:0] axi_slave_resp_i,

    // Peripheral register interface
    output core_v_mcu_reg_pkg::reg_req_t  [core_v_mcu_pkg::NumRegSlaves-1:0] reg_req_o,
    input  core_v_mcu_reg_pkg::reg_resp_t [core_v_mcu_pkg::NumRegSlaves-1:0] reg_resp_i

);

  // Package import
  import core_v_mcu_pkg::*;
  import core_v_mcu_axi_pkg::*;
  import core_v_mcu_reg_pkg::*;

  // Output slaves of the AXI_XBAR is NumAxiSlaves + 1 that goes to the reg bus
  localparam int unsigned NumAxiSlavesInt = NumAxiSlaves + 1;
  localparam int unsigned NumRegSlavesIdx = NumRegSlaves > 1 ? $clog2(NumRegSlaves) : 32'd1;
  // Internal signals
  // ----------------
  axi_req_t [NumAxiSlavesInt-1:0] axi_slave_req;
  axi_resp_t [NumAxiSlavesInt-1:0] axi_slave_resp;
  // AMO <--> CUT
  axi_resp_t axi_reg_amo_req;
  axi_resp_t axi_reg_amo_resp;
  // CUT <--> AXI to REG
  axi_req_t axi_reg_cut_req;
  axi_resp_t axi_reg_cut_resp;
  reg_req_t reg_in_req;
  reg_resp_t reg_in_resp;
  // Reg demux 
  logic [NumRegSlavesIdx-1:0] reg_select;

  // AXI XBAR
  //---------
  axi_xbar #(
      .Cfg          (AxiXbarCfg),     // TODO: generate in python(?)
      .ATOPs        (1),              // atomic operation support
      .Connectivity ('1),
      .slv_aw_chan_t(axi_aw_chan_t),  // TODO: for now map all to the same type
      .mst_aw_chan_t(axi_aw_chan_t),
      .w_chan_t     (axi_w_chan_t),
      .slv_b_chan_t (axi_b_chan_t),
      .mst_b_chan_t (axi_b_chan_t),
      .slv_ar_chan_t(axi_ar_chan_t),
      .mst_ar_chan_t(axi_ar_chan_t),
      .slv_r_chan_t (axi_r_chan_t),
      .mst_r_chan_t (axi_r_chan_t),
      .slv_req_t    (axi_req_t),
      .slv_resp_t   (axi_resp_t),
      .mst_req_t    (axi_req_t),
      .mst_resp_t   (axi_resp_t),
      .rule_t       (addr_rule_t)     // TODO: generate in python(?)
  ) i_axi_xbar (
      .clk_i,
      .rst_ni,
      .test_i               (1'b0),
      .slv_ports_req_i      (axi_master_req_i),
      .slv_ports_resp_o     (axi_master_resp_o),
      .mst_ports_req_o      (axi_slave_req),
      .mst_ports_resp_i     (axi_slave_resp),
      .addr_map_i           (AxiMap),             // todo: generate/pass
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
      .AxiIdWidth     (AxiIWidth),
      .AxiUserWidth   (AxiUserWidth),
      .AxiMaxReadTxns (RegMaxReadTxns),   //TODO: missing params
      .AxiMaxWriteTxns(RegMaxWriteTxns),  //TODO: missing params
      .AxiUserAsId    (1),
      .AxiUserIdMsb   (AxiUserAmoMsb),    //TODO: missing params
      .AxiUserIdLsb   (AxiUserAmoLsb),    //TODO: missing params
      .RiscvWordWidth (64),
      .NAxiCuts       (RegAmoNumCuts),    // TODO: missing params
      .axi_req_t      (axi_req_t),
      .axi_rsp_t      (axi_resp_t)
  ) i_reg_atomics (
      .clk_i,
      .rst_ni,
      .axi_slv_req_i(axi_slave_req[0]),   // TODO: can replace with param in pkg
      .axi_slv_rsp_o(axi_slave_resp[0]),  // TODO: can replace with param in pkg
      .axi_mst_req_o(axi_reg_amo_req),
      .axi_mst_rsp_i(axi_reg_amo_resp)
  );

  axi_cut #(
      .Bypass    (~RegAmoPostCut),  // TODO: missing params
      .aw_chan_t (axi_aw_chan_t),
      .w_chan_t  (axi_w_chan_t),
      .b_chan_t  (axi_b_chan_t),
      .ar_chan_t (axi_ar_chan_t),
      .r_chan_t  (axi_r_chan_t),
      .axi_req_t (axi_req_t),
      .axi_resp_t(axi_resp_t)
  ) i_reg_atomics_cut (
      .clk_i,
      .rst_ni,
      .slv_req_i (axi_reg_amo_req),
      .slv_resp_o(axi_reg_amo_resp),
      .mst_req_o (axi_reg_cut_req),
      .mst_resp_i(axi_reg_cut_resp)
  );

  // Convert from AXI to reg protocol
  axi_to_reg_v2 #(
      .AxiAddrWidth(AddrWidth),
      .AxiDataWidth(AxiDataWidth),
      .AxiIdWidth  (AxiIdWidth),
      .AxiUserWidth(AxiUserWidth),
      .RegDataWidth(32),
      .CutMemReqs  (RegAdaptMemCut), // TODO: missing params
      .axi_req_t   (axi_req_t),
      .axi_rsp_t   (axi_resp_t),
      .reg_req_t   (reg_req_t),
      .reg_rsp_t   (reg_resp_t)
  ) i_axi_to_reg_v2 (
      .clk_i,
      .rst_ni,
      .axi_req_i(axi_reg_cut_req),
      .axi_rsp_o(axi_reg_cut_rsp),
      .reg_req_o(reg_in_req),
      .reg_rsp_i(reg_in_resp),
      .reg_id_o (),
      .busy_o   ()
  );

  // Non-matching addresses are directed to an error slave
  addr_decode #(
      .NoIndices(NumRegSlaves),
      .NoRules  (word_bt'(RegOut.num_rules)),
      .addr_t   (addr_t),
      .rule_t   (addr_rule_t)
  ) i_reg_demux_decode (
      .addr_i          (reg_in_req.addr),
      .addr_map_i      (RegMap),  // TODO: modify
      .idx_o           (reg_select),
      .dec_valid_o     (),
      .dec_error_o     (),
      .en_default_idx_i(1'b1),
      .default_idx_i   ((cf_math_pkg::idx_width(word_bt'(RegOut.num_out)))'(RegOut.err)) // TODO: modify
  );

  reg_demux #(
      .NoPorts(NumRegSlaves),
      .req_t  (reg_req_t),
      .rsp_t  (reg_resp_t)
  ) i_reg_demux (
      .clk_i,
      .rst_ni,
      .in_select_i(reg_select),
      .in_req_i   (reg_in_req),
      .in_rsp_o   (reg_in_resp),
      .out_req_o  (reg_req_o),
      .out_rsp_i  (reg_resp_i)
  );


  assign axi_slave_req_o = axi_slave_req[NumAxiSlaves:1];
  assign axi_slave_resp[NumAxiSlaves:1] = axi_slave_resp_i;


endmodule
