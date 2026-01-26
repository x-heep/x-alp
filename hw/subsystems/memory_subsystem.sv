module memory_subsystem (

    // Clock and Reset
    input logic clk_i,
    input logic rst_ni,

    // AXI bus request
    input  core_v_mcu_pkg::axi_slv_req_t bus_req_i,
    // AXI bus response
    output core_v_mcu_pkg::axi_slv_rsp_t bus_rsp_o

);

    /* verilator lint_off PINCONNECTEMPTY */
    /* verilator lint_off UNUSEDSIGNAL */

    localparam int AddrWidth = $clog2(8192) + 1;  // 64 KB SRAM (8192 words * 8 bytes/word)

    logic                 mem_req;
    logic [AddrWidth-1:0] mem_addr;
    logic [         63:0] mem_wdata;
    logic                 mem_we;
    logic [         63:0] mem_rdata;

    axi_to_mem #(
        .axi_req_t   (core_v_mcu_pkg::axi_slv_req_t),
        .axi_resp_t  (core_v_mcu_pkg::axi_slv_rsp_t),
        .AddrWidth   (AddrWidth),
        .DataWidth   (64),
        .NumBanks    (1),
        .BufDepth    (1),
        .HideStrb    (0),
        .OutFifoDepth(1)
    ) u_axi_to_mem (
        .clk_i       (clk_i),
        .rst_ni      (rst_ni),
        .busy_o      (),
        .axi_req_i   (bus_req_i),
        .axi_resp_o  (bus_rsp_o),
        .mem_req_o   (mem_req),
        .mem_gnt_i   (mem_gnt),
        .mem_addr_o  (mem_addr),
        .mem_wdata_o (mem_wdata),
        .mem_strb_o  (),
        .mem_atop_o  (),
        .mem_we_o    (mem_we),
        .mem_rvalid_i(mem_valid_q),
        .mem_rdata_i (mem_rdata)
    );

    logic mem_valid_q;
    logic mem_valid;
    logic mem_gnt;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            mem_valid_q <= '0;
        end else begin
            mem_valid_q <= mem_req;
        end
    end

    assign mem_gnt   = 1'b1;
    assign mem_valid = mem_valid_q;

    sram_wrapper #(
        .NumWords (8192),
        .DataWidth(64)
    ) u_ram0 (
        .clk_i           (clk_i),
        .rst_ni          (rst_ni),
        .req_i           (mem_req),
        .we_i            (mem_we),
        .addr_i          ({2'b00, mem_addr[AddrWidth-1:3]}),
        .wdata_i         (mem_wdata),
        .be_i            ('1),
        .pwrgate_ni      ('1),
        .pwrgate_ack_no  (),
        .set_retentive_ni('1),
        .rdata_o         (mem_rdata)
    );

endmodule : memory_subsystem
