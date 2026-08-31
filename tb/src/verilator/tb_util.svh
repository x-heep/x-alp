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
// export "DPI-C" task tb_release_request;
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
    logic [63:0] MemBaseAddr;
    int unsigned i, w_addr, base_addr;

    // Addresses arrive as CPU-visible addresses; make them relative to the
    // base of the region being written so they index the backing array.
    MemBaseAddr = MemType ? core_v_mcu_pkg::LLC_BUS_BASE_ADDR : core_v_mcu_pkg::DRAM_BUS_BASE_ADDR;

    // Write to DRAM or SPM
    base_addr   = addr - MemBaseAddr;
    for (i = 0; i < EffChunkLength; i = i + BytesPerMemWord) begin
        w_addr = (base_addr + i) / BytesPerMemWord; // move of 1 position in the array sram for each memword (8 bytes)
        tb_writetoSram(MemType, w_addr, chunk[i+7], chunk[i+6], chunk[i+5], chunk[i+4], chunk[i+3],
                       chunk[i+2], chunk[i+1], chunk[i]);
        //end
    end
endtask

// SPM words are striped way-major: the low bits index a way's own SRAM, the
// high bits pick the way. Keep in step with axi_llc's SPM decoding.
localparam int unsigned SpmWayAddrWidth = $clog2(
    core_v_mcu_pkg::LLC_NUM_LINES
) + $clog2(
    core_v_mcu_pkg::LLC_NUM_BLOCKS
);
localparam int unsigned SpmWayIdxWidth = $clog2(core_v_mcu_pkg::LLC_SET_ASSOC);

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

    logic [SpmWayAddrWidth-1:0] way_addr;
    logic [ SpmWayIdxWidth-1:0] way_idx;
    logic [               63:0] wdata;

    wdata = {val7, val6, val5, val4, val3, val2, val1, val0};

    if (MemType) begin  // SPM: the LLC's own data ways
        way_addr = addr[SpmWayAddrWidth-1:0];
        way_idx  = addr[SpmWayAddrWidth+:SpmWayIdxWidth];
        // A generate block cannot be indexed with a run-time variable, so the way
        // select is spelled out. Arms past LLC_SET_ASSOC are never selected.
        case (way_idx)
            0:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[0].i_data_way.i_data_sram.sram[way_addr] = wdata;
            1:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[1].i_data_way.i_data_sram.sram[way_addr] = wdata;
            2:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[2].i_data_way.i_data_sram.sram[way_addr] = wdata;
            3:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[3].i_data_way.i_data_sram.sram[way_addr] = wdata;
            4:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[4].i_data_way.i_data_sram.sram[way_addr] = wdata;
            5:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[5].i_data_way.i_data_sram.sram[way_addr] = wdata;
            6:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[6].i_data_way.i_data_sram.sram[way_addr] = wdata;
            7:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[7].i_data_way.i_data_sram.sram[way_addr] = wdata;
            8:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[8].i_data_way.i_data_sram.sram[way_addr] = wdata;
            9:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[9].i_data_way.i_data_sram.sram[way_addr] = wdata;
            10:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[10].i_data_way.i_data_sram.sram[way_addr] = wdata;
            11:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[11].i_data_way.i_data_sram.sram[way_addr] = wdata;
            12:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[12].i_data_way.i_data_sram.sram[way_addr] = wdata;
            13:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[13].i_data_way.i_data_sram.sram[way_addr] = wdata;
            14:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[14].i_data_way.i_data_sram.sram[way_addr] = wdata;
            15:
            u_x_alp.u_core_v_mcu.u_axi_llc.i_axi_llc_top_raw.i_llc_ways.gen_data_ways[15].i_data_way.i_data_sram.sram[way_addr] = wdata;
            default: $error("tb_writetoSram: SPM way %0d out of range", way_idx);
        endcase
    end else begin  // DRAM: the model hanging off the LLC master port
        u_tb_dram.tc_ram_i.sram[addr] = wdata;
    end
endtask

// Point the boot ROM at the preloaded image before releasing it from its wait
// loop; without this it jumps to the BOOT_ADDRESS reset value.
task tb_write_entry_address;
    input longint unsigned entry_addr;
    u_x_alp.u_core_v_mcu.u_soc_ctrl.testbench_set_boot_address[0]    = entry_addr[31:0];
    u_x_alp.u_core_v_mcu.u_soc_ctrl.testbench_set_boot_address_en[0] = 1'b1;
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
        start_addr = core_v_mcu_pkg::DRAM_BUS_BASE_ADDR;
    else  // SPM
        start_addr = core_v_mcu_pkg::LLC_BUS_BASE_ADDR;
endtask

// Get chunk length for section loading
// ------------------------------------
task tb_get_section_chunk_length;
    output longint unsigned chunk_length;
    chunk_length = SectionChunkLength;
endtask

//`endif

