// Copyright 2025 EPFL and Politecnico di Torino.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// File: tb_cheshire_util.svh.tpl
// Author: Flavia Guella
// Date: 03/12/2025



`ifdef VERILATOR
// Tasks for loading mem using C++ DPI
export "DPI-C" task tb_loadChunk;
export "DPI-C" task tb_writetoSram;
// Force mode functions
export "DPI-C" task tb_write_entry_address;
export "DPI-C" task tb_preload_force;
export "DPI-C" task tb_release_request;
// Get parameters for tb
export "DPI-C" task tb_get_entry_address;
export "DPI-C" task tb_get_section_chunk_length;
`endif

`ifdef VERILATOR
  `define TOP i_cheshire_soc
`else
  `define TOP dut
`endif

import cheshire_pkg::*;

// TODO: change, so small just to verify
localparam longint unsigned SectionChunkLength = 256; // 256B chunks, can be changed

`define WRITE_SPM(bank_idx) \
    task automatic writeSPM_``bank_idx``(input int bank_addr, \
      input logic [7:0] val0, val1, val2, val3, val4, val5, val6, val7); \
  endtask

// Generate write tasks for each bank
% for i in range(LlcSetAssoc):
`WRITE_SPM(${i})
% endfor


//---------------
// Mem Load Force
//---------------
`ifdef VERILATOR
task automatic tb_loadChunk;
  input bit MemType; // 0: DRAM, 1: SPM
  input longint unsigned addr;
  input byte chunk[SectionChunkLength]; // chunk to write
  input longint unsigned EffChunkLength; // actual chunk size
  localparam int unsigned BytesPerMemWord = cheshire_pkg::DefaultCfg.AxiDataWidth/8;
  logic [63:0] MemBaseAddr = (MemType) ?  AmSpm : DefaultCfg.LlcOutRegionStart;
  longint unsigned i, w_addr, base_addr;

  // Write to DRAM or SPM
  base_addr = addr - MemBaseAddr;
  for (i=0; i < EffChunkLength; i = i + BytesPerMemWord) begin
    w_addr = (base_addr + i) / BytesPerMemWord; // move of 1 position in the array sram for each memword (8 bytes)
    tb_writetoSram(MemType, w_addr, chunk[i+7], chunk[i+6],
                                          chunk[i+5], chunk[i+4],
                                          chunk[i+3], chunk[i+2],
                                          chunk[i+1], chunk[i]);
    //end
  end
endtask
`else
  task automatic tb_loadChunk(
    input bit MemType,                // 0: DRAM, 1: SPM
    input longint unsigned addr,
    input byte chunk[],          // dynamic packed byte array
    input longint unsigned EffChunkLength
  );
    localparam int unsigned BytesPerMemWord =
        cheshire_pkg::DefaultCfg.AxiDataWidth / 8;

    logic [63:0] MemBaseAddr =
        (MemType) ? AmSpm : DefaultCfg.LlcOutRegionStart;

    longint unsigned i, w_addr, base_addr;

    base_addr = addr - MemBaseAddr;

    for (i = 0; i < EffChunkLength; i = i + BytesPerMemWord) begin
      w_addr = (base_addr + i) / BytesPerMemWord;

      tb_writetoSram(MemType, w_addr,
                     chunk[i+7], chunk[i+6],
                     chunk[i+5], chunk[i+4],
                     chunk[i+3], chunk[i+2],
                     chunk[i+1], chunk[i]);
    end
  endtask
`endif


task automatic tb_writetoSram;
  input bit MemType; // 0: DRAM, 1: SPM
  input longint unsigned addr;
  input [7:0] val7;
  input [7:0] val6;
  input [7:0] val5;
  input [7:0] val4;
  input [7:0] val3;
  input [7:0] val2;
  input [7:0] val1;
  input [7:0] val0;
  // should not count the word offset as it is removed by the loadChunk function when calculating w_addr /8
  localparam int unsigned SpmBankAddrRange = $clog2(cheshire_pkg::DefaultCfg.LlcNumLines) +
              $clog2(cheshire_pkg::DefaultCfg.LlcNumBlocks);
  
  int unsigned bank_id;
  logic [SpmBankAddrRange-1:0] bank_addr;
  logic [$clog2(cheshire_pkg::DefaultCfg.LlcSetAssoc)-1:0] set_id;
  if (MemType != 0) begin
    // MSBs Bits of the address
    set_id = addr[SpmBankAddrRange +: $clog2(cheshire_pkg::DefaultCfg.LlcSetAssoc)];
    bank_addr = addr[SpmBankAddrRange-1:0];
    
    // templated to support different ways
    case(set_id)
      % for i in range(LlcSetAssoc):
      ${i}: writeSPM_${i}(bank_addr, val0, val1, val2, val3, val4, val5, val6, val7);
      % endfor
      default: begin
        $exit("Currently unsupported SPM mode with VPUs");
        $error("tb_writetoSram: SPM set_id %0d out of range", set_id);
      end
    endcase
  end else begin
    vip.i_dram_sim.i_mem_sim.sram[addr] = {
      val7, val6, val5, val4, val3, val2, val1, val0
    };
  end
endtask

//-------------------------
// Control the boot process
//-------------------------
task tb_write_entry_address;
  input longint entry_addr;
  // Write start address at SCRATCH[1:0]
  `TOP.tb_force_start_addr_low[0] = 32'(entry_addr);
  `TOP.tb_force_start_addr_high[0] = '0;
  `TOP.tb_force_start_addr_de[0] = 1'b1;

endtask

task tb_preload_force;
  // Write scratch_2 reg bit 0 to inform preload is complete and start execution
  `TOP.tb_force_sim_start_de[0] = 1'b1;
endtask


task tb_release_request;
  `TOP.tb_force_start_addr_de[0] = 1'b0;
  `TOP.tb_force_sim_start_de[0] = 1'b0;
endtask


//--------------
// Shared params
//--------------


// Get DRAM or SPM start address
// -----------------------------
task tb_get_entry_address;
  input bit MemType; // 0: DRAM, 1: SPM
  output longint unsigned start_addr;
  if (MemType == 0) // DRAM
    start_addr = DefaultCfg.LlcOutRegionStart;
  else // SPM
    start_addr = AmSpm;
endtask

// Get chunk length for section loading
// ------------------------------------
task tb_get_section_chunk_length;
  output longint unsigned chunk_length;
  chunk_length = SectionChunkLength;
endtask

