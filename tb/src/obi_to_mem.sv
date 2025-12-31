// Copyright 2022 EPFL and Politecnico di Torino.
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// File: carus_obi_to_sram.sv
// Author: Michele Caon
// Date: 06/12/2022
// Description: OBI to SRAM interface

module obi_to_mem #(
    // OBI request type, expected to contain:
    //    logic           req     > request
    //    logic           we      > write enable
    //    logic [BEW-1:0] be      > byte enable
    //    logic  [AW-1:0] addr    > target address
    //    logic  [DW-1:0] wdata   > data to write
    parameter type obi_req_t = logic,
    // OBI response type, expected to contain:
    //    logic           gnt     > request accepted
    //    logic           rvalid  > read data is valid
    //    logic  [DW-1:0] rdata   > read data
    parameter type obi_resp_t = logic,
    // SRAM request type, expected to contain:
    //    logic           req     > request
    //    logic           we      > write enable
    //    logic [BEW-1:0] be      > byte enable
    //    logic  [AW-1:0] addr    > target address
    //    logic  [DW-1:0] wdata   > data to write
    parameter type mem_req_t = logic,
    // SRAM response type, expected to contain:
    //    logic  [DW-1:0] rdata   > read data
    parameter type mem_resp_t = logic,
    parameter int unsigned Latency = 'd1  // SRAM read Latency
) (
    input logic clk_i,
    input logic rst_ni,

    // OBI interface
    input  obi_req_t  obi_req_i,  // OBI bus request
    output obi_resp_t obi_resp_o, // OBI bus response

    // SRAM interface
    output mem_req_t  mem_req_o,  // SRAM request
    input  mem_resp_t mem_resp_i  // SRAM response
);
  // INTERNAL SIGNALS
  // ----------------
  logic obi_rvalid[Latency+1];

  // OBI rvalid Latency chain
  // ----------------------
  // The OBI rvalid signal is asserted when the memory produces the output
  // data, that is a number of clock cycles equal to the memory latency after
  // the input request is accepted (i.e., OBI gnt is asserted).
  // NOTE: OBI expects the rvalid signal to be asserted for each request,
  //       including store request for which no data is provided by the slave.
  assign obi_rvalid[0] = obi_req_i.req;
  generate
    for (genvar i = 1; unsigned'(i) <= Latency; i++) begin : gen_rvalid_Latency
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          obi_rvalid[i] <= 1'b0;
        end else begin
          obi_rvalid[i] <= obi_rvalid[i-1];
        end
      end
    end
  endgenerate

  // OUTPUT EVALUATION
  // -----------------

  // OBI request to SRAM request
  assign mem_req_o.req   = obi_req_i.req;
  assign mem_req_o.we    = obi_req_i.we;
  assign mem_req_o.be    = obi_req_i.be;
  assign mem_req_o.addr  = obi_req_i.addr;
  assign mem_req_o.wdata = obi_req_i.wdata;

  // SRAM response to OBI response
  assign obi_resp_o.gnt    = 1'b1;  // SRAM slways ready to accept requests
  assign obi_resp_o.rvalid = obi_rvalid[Latency];
  assign obi_resp_o.rdata  = mem_resp_i.rdata;
endmodule
