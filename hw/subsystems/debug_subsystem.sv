module debug_subsystem (
    input logic clk_i,
    input logic rst_ni,

    // AXI Slave Interface
    input  core_v_mcu_pkg::axi_slv_req_t axi_slv_req_i,
    output core_v_mcu_pkg::axi_slv_rsp_t axi_slv_rsp_o,

    // AXI Master Interface
    output core_v_mcu_pkg::axi_mst_req_t axi_mst_req_o,
    input  core_v_mcu_pkg::axi_mst_rsp_t axi_mst_rsp_i,

    // JTAG Interface
    input  logic jtag_tck_i,
    input  logic jtag_tms_i,
    input  logic jtag_trst_ni,
    input  logic jtag_tdi_i,
    output logic jtag_tdo_o,
    output logic jtag_tdo_oe_o,
    // Test mode
    input  logic test_mode_i,
    // Debug signals
    output logic dbg_active_o,
    output logic dbg_req_o

);

    logic                         dbg_slv_req;
    core_v_mcu_pkg::addr_t        dbg_slv_addr;
    core_v_mcu_pkg::axi_data_t    dbg_slv_wdata;
    core_v_mcu_pkg::axi_strb_t    dbg_slv_wstrb;
    logic                         dbg_slv_we;
    logic                         dbg_slv_rvalid;
    core_v_mcu_pkg::axi_data_t    dbg_slv_rdata;
    logic                         dbg_slv_rvalid_q;

    logic                         dbg_sba_req;
    core_v_mcu_pkg::addr_t        dbg_sba_addr;
    core_v_mcu_pkg::axi_data_t    dbg_sba_addr_long;
    logic                         dbg_sba_we;
    core_v_mcu_pkg::axi_data_t    dbg_sba_wdata;
    core_v_mcu_pkg::axi_strb_t    dbg_sba_strb;
    logic                         dbg_sba_gnt;
    core_v_mcu_pkg::axi_data_t    dbg_sba_rdata;
    logic                         dbg_sba_rvalid;
    logic                         dbg_sba_err;

    core_v_mcu_pkg::axi_mst_req_t axi_dbg_req;

    logic                         dbg_dmi_rst_n;
    dm::dmi_req_t                 dbg_dmi_req;
    logic dbg_dmi_req_ready, dbg_dmi_req_valid;
    dm::dmi_resp_t dbg_dmi_rsp;
    logic dbg_dmi_rsp_ready, dbg_dmi_rsp_valid;

    axi_to_mem_interleaved #(
        .axi_req_t (core_v_mcu_pkg::axi_slv_req_t),
        .axi_resp_t(core_v_mcu_pkg::axi_slv_rsp_t),
        .AddrWidth (core_v_mcu_pkg::AxiAddrWidth),
        .DataWidth (core_v_mcu_pkg::AxiDataWidth),
        .IdWidth   (core_v_mcu_pkg::AxiSlvIdWidth),
        .NumBanks  (1),
        .BufDepth  (4)
    ) i_dbg_slv_axi_to_mem (
        .clk_i       (clk_i),
        .rst_ni      (rst_ni),
        .test_i      (test_mode_i),
        .busy_o      (),
        .axi_req_i   (axi_slv_req_i),
        .axi_resp_o  (axi_slv_rsp_o),
        .mem_req_o   (dbg_slv_req),
        .mem_gnt_i   (dbg_slv_req),
        .mem_addr_o  (dbg_slv_addr),
        .mem_wdata_o (dbg_slv_wdata),
        .mem_strb_o  (dbg_slv_wstrb),
        .mem_atop_o  (),
        .mem_we_o    (dbg_slv_we),
        .mem_rvalid_i(dbg_slv_rvalid),
        .mem_rdata_i (dbg_slv_rdata)
    );

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            dbg_slv_rvalid_q <= '0;
        end else begin
            dbg_slv_rvalid_q <= dbg_slv_req;
        end
    end

    assign dbg_slv_rvalid = dbg_slv_rvalid_q;

    // Debug Module
    dm_top #(
        .NrHarts      (1),
        .BusWidth     (core_v_mcu_pkg::AxiDataWidth),
        .DmBaseAddress(core_v_mcu_pkg::DEBUG_S_BUS_BASE_ADDR)
    ) i_dbg_dm_top (
        .clk_i               (clk_i),
        .rst_ni              (rst_ni),
        .next_dm_addr_i      ('h50),
        .testmode_i          (test_mode_i),
        .ndmreset_o          (),
        .ndmreset_ack_i      (1'b0),
        .dmactive_o          (dbg_active_o),
        .debug_req_o         (dbg_req_o),
        .unavailable_i       ('0),
        .hartinfo_i          (cva6_config_pkg::DebugHartInfo),
        .slave_req_i         (dbg_slv_req),
        .slave_we_i          (dbg_slv_we),
        .slave_addr_i        (dbg_slv_addr),
        .slave_be_i          (dbg_slv_wstrb),
        .slave_wdata_i       (dbg_slv_wdata),
        .slave_rdata_o       (dbg_slv_rdata),
        .master_req_o        (dbg_sba_req),
        .master_add_o        (dbg_sba_addr),
        .master_we_o         (dbg_sba_we),
        .master_wdata_o      (dbg_sba_wdata),
        .master_be_o         (dbg_sba_strb),
        .master_gnt_i        (dbg_sba_gnt),
        .master_r_valid_i    (dbg_sba_rvalid),
        .master_r_rdata_i    (dbg_sba_rdata),
        .master_r_err_i      (dbg_sba_err),
        .master_r_other_err_i(1'b0),
        .dmi_rst_ni          (dbg_dmi_rst_n),
        .dmi_req_valid_i     (dbg_dmi_req_valid),
        .dmi_req_ready_o     (dbg_dmi_req_ready),
        .dmi_req_i           (dbg_dmi_req),
        .dmi_resp_valid_o    (dbg_dmi_rsp_valid),
        .dmi_resp_ready_i    (dbg_dmi_rsp_ready),
        .dmi_resp_o          (dbg_dmi_rsp)

    );

    always_comb begin
        axi_mst_req_o         = axi_dbg_req;
        axi_mst_req_o.aw.user = '0;
        axi_mst_req_o.w.user  = '0;
        axi_mst_req_o.ar.user = '0;
    end

    // Debug module system bus access to AXI crossbar
    axi_from_mem #(
        .MemAddrWidth(core_v_mcu_pkg::AxiAddrWidth),
        .AxiAddrWidth(core_v_mcu_pkg::AxiAddrWidth),
        .DataWidth   (core_v_mcu_pkg::AxiDataWidth),
        .MaxRequests (16),
        .AxiProt     ('0),
        .axi_req_t   (core_v_mcu_pkg::axi_mst_req_t),
        .axi_rsp_t   (core_v_mcu_pkg::axi_mst_rsp_t)
    ) i_dbg_sba_axi_from_mem (
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),
        .mem_req_i      (dbg_sba_req),
        .mem_addr_i     (dbg_sba_addr),
        .mem_we_i       (dbg_sba_we),
        .mem_wdata_i    (dbg_sba_wdata),
        .mem_be_i       (dbg_sba_strb),
        .mem_gnt_o      (dbg_sba_gnt),
        .mem_rsp_valid_o(dbg_sba_rvalid),
        .mem_rsp_rdata_o(dbg_sba_rdata),
        .mem_rsp_error_o(dbg_sba_err),
        .slv_aw_cache_i (axi_pkg::CACHE_MODIFIABLE),
        .slv_ar_cache_i (axi_pkg::CACHE_MODIFIABLE),
        .axi_req_o      (axi_dbg_req),
        .axi_rsp_i      (axi_mst_rsp_i)
    );

    // Debug Transfer Module and JTAG interface
    dmi_jtag #(
        .IdcodeValue(core_v_mcu_pkg::JTAG_IDCODE)
    ) i_dbg_dmi_jtag (
        .clk_i           (clk_i),
        .rst_ni          (rst_ni),
        .testmode_i      (test_mode_i),
        .dmi_rst_no      (dbg_dmi_rst_n),
        .dmi_req_o       (dbg_dmi_req),
        .dmi_req_ready_i (dbg_dmi_req_ready),
        .dmi_req_valid_o (dbg_dmi_req_valid),
        .dmi_resp_i      (dbg_dmi_rsp),
        .dmi_resp_ready_o(dbg_dmi_rsp_ready),
        .dmi_resp_valid_i(dbg_dmi_rsp_valid),
        .tck_i           (jtag_tck_i),
        .tms_i           (jtag_tms_i),
        .trst_ni         (jtag_trst_ni),
        .td_i            (jtag_tdi_i),
        .td_o            (jtag_tdo_o),
        .tdo_oe_o        (jtag_tdo_oe_o)
    );

endmodule
