// Copyright 2022 OpenHW Group
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

//`ifndef SYNTHESIS
// Task for loading 'mem' with SystemVerilog system task $readmemh()
`ifdef VERILATOR
// Tasks for loading mem using C++ DPI
export "DPI-C" task tb_loadChunk;
export "DPI-C" task tb_writetoSram;
// Force mode functions
export "DPI-C" task tb_preload_force;
// Get parameters for tb
export "DPI-C" task tb_get_entry_address;
export "DPI-C" task tb_get_section_chunk_length;
`endif

localparam longint unsigned SectionChunkLength = 256;  // 256B chunks, can be changed

//---------------
// Mem Load Force
//---------------

task automatic tb_loadChunk;
  input bit MemType;
  input int unsigned addr;
  input byte chunk[SectionChunkLength];  // chunk to write
  input int unsigned EffChunkLength;  // actual chunk size
  localparam int unsigned BytesPerMemWord = core_v_mcu_pkg::AxiDataWidth / 8;
  logic [63:0] MemBaseAddr = '0;
  int unsigned i, w_addr, base_addr;

  // Write to DRAM or SPM
  base_addr = addr - MemBaseAddr;
  for (i = 0; i < EffChunkLength; i = i + BytesPerMemWord) begin
    w_addr = (base_addr + i) / BytesPerMemWord; // move of 1 position in the array sram for each memword (8 bytes)
    tb_writetoSram(MemType, w_addr, chunk[i+7], chunk[i+6], chunk[i+5], chunk[i+4], chunk[i+3],
                   chunk[i+2], chunk[i+1], chunk[i]);
    //end
  end
endtask

task automatic tb_writetoSram;
  input bit MemType;  // 0: DRAM, 1: SPM
  input longint unsigned addr;
  input [7:0] val7;
  input [7:0] val6;
  input [7:0] val5;
  input [7:0] val4;
  input [7:0] val3;
  input [7:0] val2;
  input [7:0] val1;
  input [7:0] val0;

    u_x_alp.u_core_v_mcu.u_memory_subsystem.u_ram0.u_tc_sram.sram[addr] = {val7, val6, val5, val4, val3, val2, val1, val0};
endtask

task tb_preload_force;
  u_x_alp.u_core_v_mcu.u_soc_ctrl.testbench_set_exit_loop[0] = 1'b1;
endtask

//--------------
// Shared params
//--------------

// Get DRAM or SPM start address
// -----------------------------
task tb_get_entry_address;
  input bit MemType;  // 0: DRAM, 1: SPM
  output longint unsigned start_addr;
  if (MemType == 0)  // DRAM
    start_addr = '0;  // DefaultCfg.LlcOutRegionStart;
  else  // SPM
    start_addr = '0;  // AmSpm;
endtask

// Get chunk length for section loading
// ------------------------------------
task tb_get_section_chunk_length;
  output longint unsigned chunk_length;
  chunk_length = SectionChunkLength;
endtask

//`endif

