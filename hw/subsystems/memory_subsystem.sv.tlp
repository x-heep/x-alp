// reference for axi-to-mem iterface : https://github.com/pulp-platform/axi/blob/master/src/axi_to_mem.sv

/* verilator lint_off UNUSED */
/* verilator lint_off MULTIDRIVEN */

module memory_subsystem

// removed obi_pkg , added these includes

  `include "../../ip/axi/assign.svh"
  `include "../../ip/axi/assign.svh"
#(
    parameter NUM_BANKS = 2
) (
    input logic clk_i,
    input logic rst_ni,

    // Clock-gating signal
    input logic [NUM_BANKS-1:0] clk_gate_en_ni,

    // substituted obi->axi

    input  axi_req_t  [NUM_BANKS-1:0] ram_req_i, 
    output axi_rsp_t [NUM_BANKS-1:0] ram_resp_o,

    // power manager signals that goes to the ASIC macros
    input logic [core_v_mcu_pkg::NUM_BANKS-1:0] pwrgate_ni,
    output logic [core_v_mcu_pkg::NUM_BANKS-1:0] pwrgate_ack_no,
    input logic [core_v_mcu_pkg::NUM_BANKS-1:0] set_retentive_ni
);

  logic [NUM_BANKS-1:0] ram_valid_q;
  // Clock-gating
  logic [NUM_BANKS-1:0] clk_cg;

// sustituted xheep->xalp

/*  OBI protocol START - scrapped

% for i, bank in enumerate(xalp.iter_ram_banks()):
  logic [${bank.size().bit_length()-1 -2}-1:0] ram_req_addr_${i};
% endfor

% for i, bank in enumerate(xalp.iter_ram_banks()):
<%
  p1 = bank.size().bit_length()-1 + bank.il_level()
  p2 = 2 + bank.il_level()
%>
  assign ram_req_addr_${i} = ram_req_i[${i}].addr[${p1}-1:${p2}];
% endfor

  for (genvar i = 0; i < NUM_BANKS; i++) begin : gen_sram

    tc_clk_gating clk_gating_cell_i (
        .clk_i,
        .en_i(clk_gate_en_ni[i]),
        .test_en_i(1'b0),
        .clk_o(clk_cg[i])
    );

    always_ff @(posedge clk_cg[i] or negedge rst_ni) begin
      if (!rst_ni) begin
        ram_valid_q[i] <= '0;
      end else begin
        ram_valid_q[i] <= ram_resp_o[i].gnt;
      end
    end

    assign ram_resp_o[i].gnt = 1'b1;
    assign ram_resp_o[i].rvalid = ram_valid_q[i];
  end 

  */ // OBI protocol END - scrapped

  // swapped the final for into the rest: inteface + ram banks modules

  AXI_BUS.Slave [NUM_BANKS-1:0]  slv;
  req_t         [NUM_BANKS-1:0]  req;
  resp_t        [NUM_BANKS-1:0]  resp;

  logic         [NUM_BANKS-1:0]  busy;
  logic         [NUM_BANKS-1:0]  mem_req;
  logic         [NUM_BANKS-1:0]  mem_gnt;  
  logic         [NUM_BANKS-1:0]  mem_addr;
  logic         [NUM_BANKS-1:0]  mem_wdata;
  logic         [NUM_BANKS-1:0]  mem_strb;
  logic         [NUM_BANKS-1:0]  mem_atop;
  logic         [NUM_BANKS-1:0]  mem_we;
  logic         [NUM_BANKS-1:0]  mem_rvalid;
  logic         [NUM_BANKS-1:0]  mem_rdata;

 %for i, bank in enumerate(xalp.NUM_BANKS()):

  `AXI_ASSIGN_TO_REQ(req[${i}], slv[${i}])
  `AXI_ASSIGN_FROM_RESP(slv[${i}], resp[${i}])
  assign req[${i}] = ram_req_i[${i}];
  assign resp[${i}] = ram_resp_o[${i}];

  axi_to_mem_intf  #(
      .ADDR_WIDTH(${bank.size().bit_length()-1 -2}-1:0),
      .DATA_WIDTH(32'd32),
      .ID_WIDTH(),
      .USER_WIDTH(),
      .NUM_BANKS(NUM_BANKS),
      .BUF_DEPTH(),
      .HIDE_STRB(),
      .OUT_FIFO_DEPTH()
  ) axi_to_mem_intf${bank.name()}_i (
      .clk_i(clk_cg[${i}]),
      .rst_ni(rst_ni),
      .busy_o(busy[${i}]),
      .slv(slv[${i}]),
      .mem_req_o(mem_req[${i}]),
      .mem_gnt_i(mem_gnt[${i}]),
      .mem_addr_o(mem_addr[${i}]),
      .mem_wdata_o(mem_wdata[${i}]),
      .mem_strb_o(mem_strb[${i}]),
      .mem_atop_o(mem_atop[${i}]),
      .mem_we_o(mem_we[${i}]),
      .mem_rvalid_i(mem_rvalid[${i}]),
      .mem_rdata_i(mem_rdata[${i}])
  );

  sram_wrapper #(
      .NumWords (${bank.size() // 4}),
      .DataWidth(32'd32)
  ) ram${bank.name()}_i (
      .clk_i(clk_cg[${i}]),
      .rst_ni(rst_ni),
      .req_i(mem_req[${i}]),
      .we_i(mem_we[${i}]),
      .addr_i(mem_addr[${i}]),
      .wdata_i(mem_wdata[${i}]),
      .be_i(ram_req_i[${i}].be),  //axi_to_mem_intf does not output a be_o, taken directly from ram_req_i , input
      .pwrgate_ni(pwrgate_ni[${i}]),
      .pwrgate_ack_no(pwrgate_ack_no[${i}]),
      .set_retentive_ni(set_retentive_ni[${i}]),
      .rdata_o(mem_rdata[${i}])
  );

%endfor

endmodule