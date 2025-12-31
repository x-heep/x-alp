// Copyright 2025 Politecnico di Torino.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// File: tc_sram_mem_wrapper.sv
// Author: Flavia Guella
// Date: 06/09/2025

module tc_sram_mem_wrapper #(
    // Bus characteristics
    parameter string BusProt = "AXI4",  // support only OBI or AXI4-ATOP
    parameter int unsigned AddrWidth = 32,
    parameter int unsigned DataWidth = 32,
    parameter int unsigned IdWidth = 4,
    // Memory characteristics
    parameter int unsigned MemNumWords = 1024,
    parameter int unsigned Latency = 32'd1,
    // Interface types
    parameter type req_t = logic,
    parameter type resp_t = logic
) (
    input  logic  clk_i,
    input  logic  rst_ni,
    input  req_t  req_i,
    output resp_t resp_o
);

  // Internal signals
  // ----------------
  // AXI adapter
  // counter management
  logic axi_rvalid[Latency+1];
  // OBI adapter
  // TC_SRAM request
  typedef struct packed {
    logic                   req;
    logic                   we;
    logic [DataWidth/8-1:0] be;
    logic [AddrWidth-1:0]   addr;
    logic [DataWidth-1:0]   wdata;
  } sram_req_t;
  // TC_SRAM response
  typedef struct packed {logic [DataWidth-1:0] rdata;} sram_resp_t;

  sram_req_t mem_req;
  sram_resp_t mem_resp;

  logic req;
  logic we;
  logic [AddrWidth-1:0] addr_r;
  logic [DataWidth-1:0] wdata;
  logic [DataWidth/8-1:0] be;
  logic [DataWidth-1:0] rdata;
  logic rvalid;

  if (BusProt == "AXI4") begin : axi4_block
    // AXI4-ATOP to SRAM wrapper
    axi_to_mem #(
        .axi_req_t   (req_t),
        .axi_resp_t  (resp_t),
        .AddrWidth   (AddrWidth),
        .DataWidth   (DataWidth),
        .IdWidth     (IdWidth),
        .NumBanks    (1),
        .BufDepth    (Latency),
        .OutFifoDepth(1)
    ) u_axi_to_mem (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .busy_o  (/*unused*/),
        .axi_req_i(req_i),
        .axi_resp_o(resp_o),
        // Memory interface
        .mem_req_o(req),
        .mem_gnt_i(1'b1), // always ready to accept requests
        .mem_addr_o(addr_r),
        .mem_wdata_o(wdata),
        .mem_we_o(we),
        .mem_strb_o(be),
        .mem_rdata_i(rdata),
        .mem_rvalid_i(rvalid),
        .mem_atop_o(/*unused*/)
    );
  end else begin : obi_block
    // OBI to SRAM wrapper
    obi_to_mem #(
        .obi_req_t (req_t),
        .obi_resp_t(resp_t),
        .mem_req_t (sram_req_t),
        .mem_resp_t(sram_resp_t),
        .Latency   (Latency)
    ) u_obi_to_mem (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .obi_req_i(req_i),
        .obi_resp_o(resp_o),
        .mem_req_o(mem_req),
        .mem_resp_i(mem_resp)
    );
    assign req            = mem_req.req;
    assign we             = mem_req.we;
    assign addr_r         = mem_req.addr;
    assign wdata          = mem_req.wdata;
    assign be             = mem_req.be;
    assign mem_resp.rdata = rdata;
  end

  // Delay rvalid of latency cycles with respect to req
  // to match the latency of the SRAM model
  generate
    for (genvar i = 1; i <= Latency; i++) begin : gen_rvalid_delay
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          axi_rvalid[i] <= 1'b0;
        end else begin
          axi_rvalid[i] <= axi_rvalid[i-1];
        end
      end
    end
  endgenerate
  assign axi_rvalid[0] = req;
  assign rvalid = axi_rvalid[Latency];

  //----------------
  // Memory instance
  //----------------

  // Single bank memory for ease of writing from testbench
  tc_sram #(
      .NumWords(MemNumWords),
      .DataWidth(DataWidth),
      .NumPorts(1),  //single port
      .Latency(Latency)
  ) i_mem_sim (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .req_i(req),
      .we_i(we),
      .addr_i(addr_r[AddrWidth-1:3]),
      .wdata_i(wdata),
      .be_i(be),
      .rdata_o(rdata)
  );

endmodule
