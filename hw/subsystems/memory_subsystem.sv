module memory_subsystem (

  // Clock and Reset
  input logic clk_i,
  input logic rst_ni,

  // AXI bus request
  input  core_v_mcu_axi_pkg::axi_req_t  bus_req_i,
  // AXI bus response
  output core_v_mcu_axi_pkg::axi_resp_t bus_resp_o

);

  /* verilator lint_off PINCONNECTEMPTY */
  /* verilator lint_off UNUSEDSIGNAL */

  localparam int AddrWidth = $clog2(8192);  // 8 KB SRAM

  logic                 mem_req;
  logic [AddrWidth-1:0] mem_addr;
  logic [         63:0] mem_wdata;
  logic                 mem_we;
  logic [         63:0] mem_rdata;

  axi_to_mem #(
    .axi_req_t   (core_v_mcu_axi_pkg::axi_req_t),
    .axi_resp_t  (core_v_mcu_axi_pkg::axi_resp_t),
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
    .axi_resp_o  (bus_resp_o),
    .mem_req_o   (mem_req),
    .mem_gnt_i   (),
    .mem_addr_o  (mem_addr),
    .mem_wdata_o (mem_wdata),
    .mem_strb_o  (),
    .mem_atop_o  (),
    .mem_we_o    (mem_we),
    .mem_rvalid_i(),
    .mem_rdata_i (mem_rdata)
  );

  sram_wrapper #(
    .NumWords (8192),
    .DataWidth(64)
  ) u_ram0 (
    .clk_i           (clk_i),
    .rst_ni          (rst_ni),
    .req_i           (mem_req),
    .we_i            (mem_we),
    .addr_i          (mem_addr),
    .wdata_i         (mem_wdata),
    .be_i            ('1),
    .pwrgate_ni      ('1),
    .pwrgate_ack_no  (),
    .set_retentive_ni('1),
    .rdata_o         (mem_rdata)
  );

endmodule : memory_subsystem
