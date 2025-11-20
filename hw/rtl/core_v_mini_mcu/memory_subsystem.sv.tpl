// Memory subsystem by AB
// reference for axi-to-mem iterface : https://github.com/pulp-platform/axi/blob/master/src/axi_to_mem.sv

/* verilator lint_off UNUSED */
/* verilator lint_off MULTIDRIVEN */

module mempory_subsystem

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
    input logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] pwrgate_ni,
    output logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] pwrgate_ack_no,
    input logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] set_retentive_ni
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

  AXI_BUS.Slave [xalp.iter_ram_banks()]  slv;
  req_t         [xalp.iter_ram_banks()]  req;
  resp_t        [xalp.iter_ram_banks()]  resp;

  logic         [xalp.iter_ram_banks()]  busy_o;
  logic         [xalp.iter_ram_banks()]  mem_req_o;
  logic         [xalp.iter_ram_banks()]  mem_gnt_i;  
  logic         [xalp.iter_ram_banks()]  mem_addr_o;
  logic         [xalp.iter_ram_banks()]  mem_wdata_o;
  logic         [xalp.iter_ram_banks()]  mem_strb_o;
  logic         [xalp.iter_ram_banks()]  mem_atop_o;
  logic         [xalp.iter_ram_banks()]  mem_we_o;
  logic         [xalp.iter_ram_banks()]  mem_rvalid_i;
  logic         [xalp.iter_ram_banks()]  mem_rdata_i;

 %for i, bank in enumerate(xalp.iter_ram_banks()):

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
      .busy_o(busy_o[${i}]),
      .slv(slv[${i}]),
      .mem_req_o(mem_req_o[${i}]),
      .mem_gnt_i(mem_gnt_i[${i}]),
      .mem_addr_o(mem_addr_o[${i}]),
      .mem_wdata_o(mem_wdata_o[${i}]),
      .mem_strb_o(mem_strb_o[${i}]),
      .mem_atop_o(mem_atop_o[${i}]),
      .mem_we_o(mem_we_o[${i}]),
      .mem_rvalid_i(mem_rvalid_i[${i}]),
      .mem_rdata_i(mem_rdata_i[${i}])
  );

  sram_wrapper #(
      .NumWords (${bank.size() // 4}),
      .DataWidth(32'd32)
  ) ram${bank.name()}_i (
      .clk_i(clk_cg[${i}]),
      .rst_ni(rst_ni),
      .req_i(mem_req_o[${i}]),
      .we_i(mem_we_o[${i}]),
      .addr_i(mem_addr_o[${i}]),
      .wdata_i(mem_wdata_o[${i}]),
      .be_i(ram_req_i[${i}].be),
      .pwrgate_ni(pwrgate_ni[${i}]),
      .pwrgate_ack_no(pwrgate_ack_no[${i}]),
      .set_retentive_ni(set_retentive_ni[${i}]),
      .rdata_o(mem_rdata_i[${i}])
  );

%endfor

endmodule