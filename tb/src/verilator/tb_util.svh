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
export "DPI-C" task tb_write_entry_address;
export "DPI-C" task tb_preload_force;
export "DPI-C" task tb_release_request;
// Get parameters for tb
export "DPI-C" task tb_get_entry_address;
export "DPI-C" task tb_get_section_chunk_length;
`endif


// TODO: change, so small just to verify
localparam longint unsigned SectionChunkLength = 256;  // 256B chunks, can be changed

//`define WRITE_SPM(bank_idx) \
//    task automatic writeSPM_``bank_idx``(input int bank_addr, \
//      input logic [7:0] val0, val1, val2, val3, val4, val5, val6, val7); \
//  endtask


// Generate write tasks for each bank
//`WRITE_SPM(0)
//`WRITE_SPM(1)
//`WRITE_SPM(2)
//`WRITE_SPM(3)
//`WRITE_SPM(4)
//`WRITE_SPM(5)
//`WRITE_SPM(6)
//`WRITE_SPM(7)


//---------------
// Mem Load Force
//---------------


`ifdef VERILATOR
task automatic tb_loadChunk;
  input bit MemType;  // 0: DRAM, 1: SPM
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
`else
task automatic tb_loadChunk(input bit MemType,  // 0: DRAM, 1: SPM
                            input longint unsigned addr,
                            input byte chunk[],  // dynamic packed byte array
                            input longint unsigned EffChunkLength);
  localparam int unsigned BytesPerMemWord = cheshire_pkg::DefaultCfg.AxiDataWidth / 8;

  logic [63:0] MemBaseAddr = 0;

  longint unsigned i, w_addr, base_addr;

  base_addr = addr - MemBaseAddr;

  for (i = 0; i < EffChunkLength; i = i + BytesPerMemWord) begin
    w_addr = (base_addr + i) / BytesPerMemWord;

    tb_writetoSram(MemType, w_addr, chunk[i+7], chunk[i+6], chunk[i+5], chunk[i+4], chunk[i+3],
                   chunk[i+2], chunk[i+1], chunk[i]);
  end
endtask
`endif

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
  // should not count the word offset as it is removed by the loadChunk function when calculating w_addr /8
  // localparam int unsigned SpmBankAddrRange = $clog2(
  //     cheshire_pkg::DefaultCfg.LlcNumLines
  // ) + $clog2(
  //     cheshire_pkg::DefaultCfg.LlcNumBlocks
  // );

  int unsigned bank_id;
  // logic [SpmBankAddrRange-1:0] bank_addr;
  // logic [$clog2(cheshire_pkg::DefaultCfg.LlcSetAssoc)-1:0] set_id;
    // Write to SRAM
    $display("[TB] INFO: Writing at addr 0x%0h data 0x%0h%0h%0h%0h%0h%0h%0h%0h",
             addr,
             val7, val6, val5, val4, val3, val2, val1, val0);
    u_x_alp.u_core_v_mcu.u_memory_subsystem.u_ram0.u_tc_sram.sram[addr] = {val7, val6, val5, val4, val3, val2, val1, val0};
endtask

//-------------------------
// Control the boot process
//-------------------------
`ifndef FAST_SIM
task tb_write_entry_address;
  input longint entry_addr;
  // // Write start address at SCRATCH[1:0]
  // `TOP.tb_force_start_addr_low[0]  = 32'(entry_addr);
  // `TOP.tb_force_start_addr_high[0] = '0;
  // `TOP.tb_force_start_addr_de[0]   = 1'b1;

endtask

task tb_preload_force;
  u_x_alp.u_core_v_mcu.u_soc_ctrl.testbench_set_exit_loop[0] = 1'b1;
endtask


task tb_release_request;
  // `TOP.tb_force_start_addr_de[0] = 1'b0;
  // `TOP.tb_force_sim_start_de[0]  = 1'b0;
endtask

`endif

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

