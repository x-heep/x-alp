// Copyright 2022 EPFL
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

<%
    memory_ss = xheep.memory_ss()
%>

`include "common_cells/assertions.svh"

module power_manager import power_manager_pkg::*; #(
    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic,
    parameter logic SWITCH_IDLE_VALUE = 1'b1, 
    parameter logic ISO_IDLE_VALUE = 1'b1, 
    parameter logic RESET_IDLE_VALUE = 1'b1, 
    parameter logic SWITCH_VALUE_AT_RESET = SWITCH_IDLE_VALUE, 
    parameter logic ISO_VALUE_AT_RESET = ISO_IDLE_VALUE, 
    parameter logic RESET_VALUE_AT_RESET = ~RESET_IDLE_VALUE, 
    parameter EXT_DOMAINS_RND = core_v_mini_mcu_pkg::EXTERNAL_DOMAINS == 0 ? 1 : core_v_mini_mcu_pkg::EXTERNAL_DOMAINS,
    parameter NEXT_INT_RND = core_v_mini_mcu_pkg::NEXT_INT == 0 ? 1 : core_v_mini_mcu_pkg::NEXT_INT,
    // Start of Platform Specific Registers (Address 0x400)
    parameter logic [31:0] PLATFORM_OFFSET = 32'h400
) (
    input logic clk_i,
    input logic rst_ni,

    // Bus Interface
    input  reg_req_t reg_req_i,
    output reg_rsp_t reg_rsp_o,

    // Status signal
    input logic core_sleep_i,

    // Input interrupt array
    input logic [31:0] intr_i,

    // External interrupts
    input logic [NEXT_INT_RND-1:0] ext_irq_i,

    // Power Manager output signals
    output power_manager_out_t cpu_subsystem_pwr_ctrl_o,
    output power_manager_out_t peripheral_subsystem_pwr_ctrl_o,
    output power_manager_out_t memory_subsystem_pwr_ctrl_o[core_v_mini_mcu_pkg::NUM_BANKS-1:0],
    output power_manager_out_t external_subsystem_pwr_ctrl_o[EXT_DOMAINS_RND-1:0],
    output power_manager_out_t dma_subsystem_pwr_ctrl_o[core_v_mini_mcu_pkg::DMA_CH_NUM-1:0],

    // Power Manager input signals
    input power_manager_in_t cpu_subsystem_pwr_ctrl_i,
    input power_manager_in_t peripheral_subsystem_pwr_ctrl_i,
    input power_manager_in_t memory_subsystem_pwr_ctrl_i[core_v_mini_mcu_pkg::NUM_BANKS-1:0],
    input power_manager_in_t external_subsystem_pwr_ctrl_i[EXT_DOMAINS_RND-1:0]

);

  // IMPORT BOTH GENERATED PACKAGES
  import power_manager_common_reg_pkg::*;
  import power_manager_xheep_reg_pkg::*;

  // Signals for Common Registers
  power_manager_common_reg2hw_t reg2hw_common;
  power_manager_common_hw2reg_t hw2reg_common;
  reg_req_t reg_req_common;
  reg_rsp_t reg_rsp_common;

  // Signals for Platform Registers
  power_manager_xheep_reg2hw_t reg2hw_plat;
  power_manager_xheep_hw2reg_t hw2reg_plat;
  reg_req_t reg_req_plat;
  reg_rsp_t reg_rsp_plat;

  logic start_on_sequence;

  logic sel_platform;
  assign sel_platform = (reg_req_i.addr >= PLATFORM_OFFSET);

  always_comb begin
      reg_req_common = '0;
      reg_req_plat   = '0;
      
      if (reg_req_i.valid) begin
          if (sel_platform) begin
              reg_req_plat.valid = 1'b1;
              reg_req_plat.write = reg_req_i.write;
              reg_req_plat.addr  = reg_req_i.addr - PLATFORM_OFFSET;
              reg_req_plat.wdata = reg_req_i.wdata;
              reg_req_plat.wstrb = reg_req_i.wstrb;
          end else begin
              reg_req_common.valid = 1'b1;
              reg_req_common.write = reg_req_i.write;
              reg_req_common.addr  = reg_req_i.addr;
              reg_req_common.wdata = reg_req_i.wdata;
              reg_req_common.wstrb = reg_req_i.wstrb;
          end
      end
  end

  logic rsp_sel_platform_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
          rsp_sel_platform_q <= 1'b0;
      end else if (reg_req_i.valid) begin
          rsp_sel_platform_q <= sel_platform;
      end
  end

  assign reg_rsp_o = rsp_sel_platform_q ? reg_rsp_plat : reg_rsp_common;
  
  power_manager_common_reg_top #(
      .reg_req_t(reg_req_t),
      .reg_rsp_t(reg_rsp_t)
  ) u_reg_top_common (
      .clk_i,
      .rst_ni,
      .reg_req_i (reg_req_common),
      .reg_rsp_o (reg_rsp_common),
      .reg2hw    (reg2hw_common),
      .hw2reg    (hw2reg_common),
      .devmode_i (1'b1)
  );

  power_manager_xheep_reg_top #(
      .reg_req_t(reg_req_t),
      .reg_rsp_t(reg_rsp_t)
  ) u_reg_top_plat (
      .clk_i,
      .rst_ni,
      .reg_req_i (reg_req_plat),
      .reg_rsp_o (reg_rsp_plat),
      .reg2hw    (reg2hw_plat),
      .hw2reg    (hw2reg_plat),
      .devmode_i (1'b1)
  );

  // Logic Implementation (Updated to use _common or _plat structs)

  assign hw2reg_common.intr_state.d[15:0] = {
    intr_i[29:22], intr_i[21], intr_i[20], intr_i[19], 
    intr_i[18], intr_i[17], intr_i[16], intr_i[11], intr_i[7]
  };

  if (core_v_mini_mcu_pkg::NEXT_INT > 16) begin: gen_ext_int_lt16
    assign hw2reg_common.intr_state.d[31:16] = ext_irq_i[15:0];
  end else begin : gen_ext_int_gt16
    assign hw2reg_common.intr_state.d[31:16] = $unsigned(ext_irq_i);
  end
  assign hw2reg_common.intr_state.de = 1'b1;

  logic cpu_subsystem_powergate_switch_n;
  logic cpu_subsystem_powergate_iso_n;
  logic cpu_subsystem_rst_n;
  logic peripheral_subsystem_powergate_switch_n;
  logic peripheral_subsystem_powergate_iso_n;
  logic peripheral_subsystem_rst_n;
  logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] memory_subsystem_banks_powergate_switch_n;
  logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] memory_subsystem_banks_powergate_iso_n;
% if external_domains != 0:
  logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] external_subsystem_powergate_switch_n;
  logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] external_subsystem_powergate_iso_n;
  logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] external_subsystem_rst_n;
% endif

  assign cpu_subsystem_pwr_ctrl_o.pwrgate_en_n = cpu_subsystem_powergate_switch_n;
  assign cpu_subsystem_pwr_ctrl_o.isogate_en_n = cpu_subsystem_powergate_iso_n;
  assign cpu_subsystem_pwr_ctrl_o.rst_n = cpu_subsystem_rst_n;
  assign cpu_subsystem_pwr_ctrl_o.clkgate_en_n = 1'b1; 
  assign cpu_subsystem_pwr_ctrl_o.retentive_en_n = 1'b1; 

  assign peripheral_subsystem_pwr_ctrl_o.pwrgate_en_n = peripheral_subsystem_powergate_switch_n;
  assign peripheral_subsystem_pwr_ctrl_o.isogate_en_n = peripheral_subsystem_powergate_iso_n;
  assign peripheral_subsystem_pwr_ctrl_o.rst_n = peripheral_subsystem_rst_n;
  assign peripheral_subsystem_pwr_ctrl_o.retentive_en_n = 1'b1; 
  assign peripheral_subsystem_pwr_ctrl_o.clkgate_en_n = ~reg2hw_common.periph_clk_gate.q;

% for bank in memory_ss.iter_ram_banks():
  assign memory_subsystem_pwr_ctrl_o[${bank.name()}].pwrgate_en_n = memory_subsystem_banks_powergate_switch_n[${bank.name()}];
  assign memory_subsystem_pwr_ctrl_o[${bank.name()}].isogate_en_n = memory_subsystem_banks_powergate_iso_n[${bank.name()}];
  assign memory_subsystem_pwr_ctrl_o[${bank.name()}].rst_n = 1'b1;
  // NOTE: RAM CLK GATE is now in Platform
  assign memory_subsystem_pwr_ctrl_o[${bank.name()}].clkgate_en_n = ~reg2hw_plat.ram_${bank.name()}_clk_gate.q;
% endfor

% for channel in range(xheep.get_base_peripheral_domain().get_dma().get_num_channels()):
  // NOTE: DMA CLK GATE is now in Platform
  assign dma_subsystem_pwr_ctrl_o[${channel}].clkgate_en_n = ~reg2hw_plat.dma_ch${channel}_clk_gate.q;
% endfor

% if external_domains != 0:
% for ext in range(external_domains):
    assign external_subsystem_pwr_ctrl_o[${ext}].pwrgate_en_n = external_subsystem_powergate_switch_n[${ext}];
    assign external_subsystem_pwr_ctrl_o[${ext}].isogate_en_n = external_subsystem_powergate_iso_n[${ext}];
    assign external_subsystem_pwr_ctrl_o[${ext}].rst_n = external_subsystem_rst_n[${ext}];
    // NOTE: External CLK GATE is now in Platform
    assign external_subsystem_pwr_ctrl_o[${ext}].clkgate_en_n = ~reg2hw_plat.external_${ext}_clk_gate.q;
% endfor
% else:
    assign external_subsystem_pwr_ctrl_o[0].pwrgate_en_n = 1'b1;
    assign external_subsystem_pwr_ctrl_o[0].isogate_en_n = 1'b1;
    assign external_subsystem_pwr_ctrl_o[0].rst_n = 1'b1;
    assign external_subsystem_pwr_ctrl_o[0].clkgate_en_n = 1'b1;
% endif

  // CPU SEQUENCE (Uses Common)
  logic cpu_subsystem_powergate_switch_ack_sync;

  sync #(.ResetValue(1'b0)) sync_cpu_ack_i (
      .clk_i, .rst_ni,
      .serial_i(cpu_subsystem_pwr_ctrl_i.pwrgate_ack_n),
      .serial_o(cpu_subsystem_powergate_switch_ack_sync)
  );

  assign hw2reg_common.power_gate_core_ack.de = 1'b1;
  assign hw2reg_common.power_gate_core_ack.d = cpu_subsystem_powergate_switch_ack_sync;

  logic cpu_switch_wait_ack;
  assign cpu_switch_wait_ack = reg2hw_common.cpu_wait_ack_switch_on_counter.q ? reg2hw_common.power_gate_core_ack.q == SWITCH_IDLE_VALUE : 1'b1;

  always_comb begin : power_manager_start_on_sequence_gen
    if ((reg2hw_common.en_wait_for_intr.q & reg2hw_common.intr_state.q)!='0) begin
      start_on_sequence = 1'b1;
    end else begin
      start_on_sequence = 1'b0;
    end
  end

  logic cpu_powergate_counter_start_reset_assert, cpu_powergate_counter_expired_reset_assert;
  logic cpu_powergate_counter_start_reset_deassert, cpu_powergate_counter_expired_reset_deassert;

  reg_to_counter #(.DW(32), .ExpireValue('0)) reg_to_counter_cpu_reset_assert_i (
      .clk_i, .rst_ni,
      .stop_i(reg2hw_common.cpu_counters_stop.cpu_reset_assert_stop_bit_counter.q),
      .start_i(cpu_powergate_counter_start_reset_assert),
      .done_o(cpu_powergate_counter_expired_reset_assert),
      .hw2reg_d_o(hw2reg_common.cpu_reset_assert_counter.d),
      .hw2reg_de_o(hw2reg_common.cpu_reset_assert_counter.de),
      .hw2reg_q_i(reg2hw_common.cpu_reset_assert_counter.q)
  );

  reg_to_counter #(.DW(32), .ExpireValue('0)) reg_to_counter_cpu_reset_deassert_i (
      .clk_i, .rst_ni,
      .stop_i(reg2hw_common.cpu_counters_stop.cpu_reset_deassert_stop_bit_counter.q),
      .start_i(cpu_powergate_counter_start_reset_deassert),
      .done_o(cpu_powergate_counter_expired_reset_deassert),
      .hw2reg_d_o(hw2reg_common.cpu_reset_deassert_counter.d),
      .hw2reg_de_o(hw2reg_common.cpu_reset_deassert_counter.de),
      .hw2reg_q_i(reg2hw_common.cpu_reset_deassert_counter.q)
  );

  power_manager_counter_sequence #(.IDLE_VALUE(RESET_IDLE_VALUE), .ONOFF_AT_RESET(RESET_VALUE_AT_RESET)) 
  power_manager_counter_sequence_cpu_reset_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i((reg2hw_common.power_gate_core.q && core_sleep_i) || reg2hw_common.master_cpu_force_reset_assert.q),
      .start_on_sequence_i (start_on_sequence || reg2hw_common.master_cpu_force_reset_deassert.q),
      .switch_ack_i (cpu_switch_wait_ack),
      .counter_expired_switch_off_i(cpu_powergate_counter_expired_reset_assert),
      .counter_expired_switch_on_i (cpu_powergate_counter_expired_reset_deassert),
      .counter_start_switch_off_o(cpu_powergate_counter_start_reset_assert),
      .counter_start_switch_on_o (cpu_powergate_counter_start_reset_deassert),
      .switch_onoff_signal_o(cpu_subsystem_rst_n)
  );

  logic cpu_powergate_counter_start_switch_off, cpu_powergate_counter_expired_switch_off;
  logic cpu_powergate_counter_start_switch_on, cpu_powergate_counter_expired_switch_on;

  reg_to_counter #(.DW(32), .ExpireValue('0)) reg_to_counter_cpu_powergate_switch_off_i (
      .clk_i, .rst_ni,
      .stop_i(reg2hw_common.cpu_counters_stop.cpu_switch_off_stop_bit_counter.q),
      .start_i(cpu_powergate_counter_start_switch_off),
      .done_o(cpu_powergate_counter_expired_switch_off),
      .hw2reg_d_o(hw2reg_common.cpu_switch_off_counter.d),
      .hw2reg_de_o(hw2reg_common.cpu_switch_off_counter.de),
      .hw2reg_q_i(reg2hw_common.cpu_switch_off_counter.q)
  );

  reg_to_counter #(.DW(32), .ExpireValue('0)) reg_to_counter_cpu_powergate_switch_on_i (
      .clk_i, .rst_ni,
      .stop_i(reg2hw_common.cpu_counters_stop.cpu_switch_on_stop_bit_counter.q),
      .start_i(cpu_powergate_counter_start_switch_on),
      .done_o(cpu_powergate_counter_expired_switch_on),
      .hw2reg_d_o(hw2reg_common.cpu_switch_on_counter.d),
      .hw2reg_de_o(hw2reg_common.cpu_switch_on_counter.de),
      .hw2reg_q_i(reg2hw_common.cpu_switch_on_counter.q)
  );

  power_manager_counter_sequence #(.IDLE_VALUE(SWITCH_IDLE_VALUE), .ONOFF_AT_RESET(SWITCH_VALUE_AT_RESET))
  power_manager_counter_sequence_cpu_switch_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i((reg2hw_common.power_gate_core.q && core_sleep_i) || reg2hw_common.master_cpu_force_switch_off.q),
      .start_on_sequence_i (start_on_sequence || reg2hw_common.master_cpu_force_switch_on.q),
      .switch_ack_i (1'b1),
      .counter_expired_switch_off_i(cpu_powergate_counter_expired_switch_off),
      .counter_expired_switch_on_i (cpu_powergate_counter_expired_switch_on),
      .counter_start_switch_off_o(cpu_powergate_counter_start_switch_off),
      .counter_start_switch_on_o (cpu_powergate_counter_start_switch_on),
      .switch_onoff_signal_o(cpu_subsystem_powergate_switch_n)
  );

  logic cpu_powergate_counter_start_iso_off, cpu_powergate_counter_expired_iso_off;
  logic cpu_powergate_counter_start_iso_on, cpu_powergate_counter_expired_iso_on;

  reg_to_counter #(.DW(32), .ExpireValue('0)) reg_to_counter_cpu_powergate_iso_off_i (
      .clk_i, .rst_ni,
      .stop_i(reg2hw_common.cpu_counters_stop.cpu_iso_off_stop_bit_counter.q),
      .start_i(cpu_powergate_counter_start_iso_off),
      .done_o(cpu_powergate_counter_expired_iso_off),
      .hw2reg_d_o(hw2reg_common.cpu_iso_off_counter.d),
      .hw2reg_de_o(hw2reg_common.cpu_iso_off_counter.de),
      .hw2reg_q_i(reg2hw_common.cpu_iso_off_counter.q)
  );

  reg_to_counter #(.DW(32), .ExpireValue('0)) reg_to_counter_cpu_powergate_iso_on_i (
      .clk_i, .rst_ni,
      .stop_i(reg2hw_common.cpu_counters_stop.cpu_iso_on_stop_bit_counter.q),
      .start_i(cpu_powergate_counter_start_iso_on),
      .done_o(cpu_powergate_counter_expired_iso_on),
      .hw2reg_d_o(hw2reg_common.cpu_iso_on_counter.d),
      .hw2reg_de_o(hw2reg_common.cpu_iso_on_counter.de),
      .hw2reg_q_i(reg2hw_common.cpu_iso_on_counter.q)
  );

  power_manager_counter_sequence #(.IDLE_VALUE(ISO_IDLE_VALUE), .ONOFF_AT_RESET(ISO_VALUE_AT_RESET))
  power_manager_counter_sequence_cpu_iso_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i((reg2hw_common.power_gate_core.q && core_sleep_i) || reg2hw_common.master_cpu_force_iso_off.q),
      .start_on_sequence_i (start_on_sequence || reg2hw_common.master_cpu_force_iso_on.q),
      .switch_ack_i (cpu_switch_wait_ack),
      .counter_expired_switch_off_i(cpu_powergate_counter_expired_iso_off),
      .counter_expired_switch_on_i (cpu_powergate_counter_expired_iso_on),
      .counter_start_switch_off_o(cpu_powergate_counter_start_iso_off),
      .counter_start_switch_on_o (cpu_powergate_counter_start_iso_on),
      .switch_onoff_signal_o(cpu_subsystem_powergate_iso_n)
  );

  // PERIPHERAL SEQUENCE (Uses Common)
  logic peripheral_subsystem_powergate_switch_ack_sync;

  sync #(.ResetValue(1'b0)) sync_periph_ack_i (
      .clk_i, .rst_ni,
      .serial_i(peripheral_subsystem_pwr_ctrl_i.pwrgate_ack_n),
      .serial_o(peripheral_subsystem_powergate_switch_ack_sync)
  );

  assign hw2reg_common.power_gate_periph_ack.de = 1'b1;
  assign hw2reg_common.power_gate_periph_ack.d = peripheral_subsystem_powergate_switch_ack_sync;

  logic periph_switch_wait_ack;
  assign periph_switch_wait_ack = reg2hw_common.periph_wait_ack_switch_on.q ? reg2hw_common.power_gate_periph_ack.q == SWITCH_IDLE_VALUE : 1'b1;

  power_manager_sequence #(.IDLE_VALUE(RESET_IDLE_VALUE), .ONOFF_AT_RESET(RESET_VALUE_AT_RESET))
  power_manager_sequence_periph_reset_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i(reg2hw_common.periph_reset.q),
      .start_on_sequence_i(~reg2hw_common.periph_reset.q),
      .switch_ack_i(periph_switch_wait_ack),
      .switch_onoff_signal_o(peripheral_subsystem_rst_n)
  );

  power_manager_sequence #(.IDLE_VALUE(SWITCH_IDLE_VALUE), .ONOFF_AT_RESET(SWITCH_VALUE_AT_RESET))
  power_manager_sequence_periph_switch_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i(reg2hw_common.periph_switch.q),
      .start_on_sequence_i(~reg2hw_common.periph_switch.q),
      .switch_ack_i(1'b1),
      .switch_onoff_signal_o(peripheral_subsystem_powergate_switch_n)
  );

  power_manager_sequence #(.IDLE_VALUE(ISO_IDLE_VALUE), .ONOFF_AT_RESET(ISO_VALUE_AT_RESET))
  power_manager_sequence_periph_iso_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i(reg2hw_common.periph_iso.q),
      .start_on_sequence_i(~reg2hw_common.periph_iso.q),
      .switch_ack_i(periph_switch_wait_ack),
      .switch_onoff_signal_o(peripheral_subsystem_powergate_iso_n)
  );

% for bank in memory_ss.iter_ram_banks():
  // RAM_${bank.name()} SEQUENCE (Uses Platform/X-HEEP)

  logic ram_${bank.name()}_subsystem_powergate_switch_ack_sync;

  sync #(.ResetValue(1'b0)) sync_ram_${bank.name()}_ack_i (
      .clk_i, .rst_ni,
      .serial_i(memory_subsystem_pwr_ctrl_i[${bank.name()}].pwrgate_ack_n),
      .serial_o(ram_${bank.name()}_subsystem_powergate_switch_ack_sync)
  );

  assign hw2reg_plat.power_gate_ram_block_${bank.name()}_ack.de = 1'b1;
  assign hw2reg_plat.power_gate_ram_block_${bank.name()}_ack.d = ram_${bank.name()}_subsystem_powergate_switch_ack_sync;

  logic ram_${bank.name()}_switch_wait_ack;
  assign ram_${bank.name()}_switch_wait_ack = reg2hw_plat.ram_${bank.name()}_wait_ack_switch_on.q ? reg2hw_plat.power_gate_ram_block_${bank.name()}_ack.q == SWITCH_IDLE_VALUE : 1'b1;

  power_manager_sequence #(.IDLE_VALUE(SWITCH_IDLE_VALUE), .ONOFF_AT_RESET(SWITCH_VALUE_AT_RESET))
  power_manager_sequence_ram_${bank.name()}_switch_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i(reg2hw_plat.ram_${bank.name()}_switch.q),
      .start_on_sequence_i (~reg2hw_plat.ram_${bank.name()}_switch.q),
      .switch_ack_i (1'b1),
      .switch_onoff_signal_o(memory_subsystem_banks_powergate_switch_n[${bank.name()}])
  );

  power_manager_sequence #(.IDLE_VALUE(ISO_IDLE_VALUE), .ONOFF_AT_RESET(ISO_VALUE_AT_RESET))
  power_manager_sequence_ram_${bank.name()}_iso_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i(reg2hw_plat.ram_${bank.name()}_iso.q),
      .start_on_sequence_i (~reg2hw_plat.ram_${bank.name()}_iso.q),
      .switch_ack_i (ram_${bank.name()}_switch_wait_ack),
      .switch_onoff_signal_o(memory_subsystem_banks_powergate_iso_n[${bank.name()}])
  );

  power_manager_sequence #(.IDLE_VALUE(ISO_IDLE_VALUE), .ONOFF_AT_RESET(ISO_VALUE_AT_RESET))
  power_manager_sequence_ram_${bank.name()}_retentive_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i(reg2hw_plat.ram_${bank.name()}_retentive.q),
      .start_on_sequence_i (~reg2hw_plat.ram_${bank.name()}_retentive.q),
      .switch_ack_i (1'b1),
      .switch_onoff_signal_o(memory_subsystem_pwr_ctrl_o[${bank.name()}].retentive_en_n)
  );

% endfor

% for ext in range(external_domains):
  // EXTERNAL_${ext} SEQUENCE (Uses Platform/X-HEEP)

  logic external_${ext}_subsystem_powergate_switch_ack_sync;

  sync #(.ResetValue(1'b0)) sync_external_${ext}_ack_i (
      .clk_i, .rst_ni,
      .serial_i(external_subsystem_pwr_ctrl_i[${ext}].pwrgate_ack_n),
      .serial_o(external_${ext}_subsystem_powergate_switch_ack_sync)
  );

  assign hw2reg_plat.power_gate_external_${ext}_ack.de = 1'b1;
  assign hw2reg_plat.power_gate_external_${ext}_ack.d = external_${ext}_subsystem_powergate_switch_ack_sync;

  logic external_${ext}_switch_wait_ack;
  assign external_${ext}_switch_wait_ack = reg2hw_plat.external_${ext}_wait_ack_switch_on.q ? reg2hw_plat.power_gate_external_${ext}_ack.q == SWITCH_IDLE_VALUE : 1'b1;

  power_manager_sequence #(.IDLE_VALUE(RESET_IDLE_VALUE), .ONOFF_AT_RESET(RESET_VALUE_AT_RESET))
  power_manager_sequence_external_${ext}_reset_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i(reg2hw_plat.external_${ext}_reset.q),
      .start_on_sequence_i (~reg2hw_plat.external_${ext}_reset.q),
      .switch_ack_i (external_${ext}_switch_wait_ack),
      .switch_onoff_signal_o(external_subsystem_rst_n[${ext}])
  );

  power_manager_sequence #(.IDLE_VALUE(SWITCH_IDLE_VALUE), .ONOFF_AT_RESET(SWITCH_VALUE_AT_RESET))
  power_manager_sequence_external_${ext}_switch_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i(reg2hw_plat.external_${ext}_switch.q),
      .start_on_sequence_i (~reg2hw_plat.external_${ext}_switch.q),
      .switch_ack_i (1'b1),
      .switch_onoff_signal_o(external_subsystem_powergate_switch_n[${ext}])
  );

  power_manager_sequence #(.IDLE_VALUE(ISO_IDLE_VALUE), .ONOFF_AT_RESET(ISO_VALUE_AT_RESET))
  power_manager_sequence_external_${ext}_iso_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i(reg2hw_plat.external_${ext}_iso.q),
      .start_on_sequence_i (~reg2hw_plat.external_${ext}_iso.q),
      .switch_ack_i (external_${ext}_switch_wait_ack),
      .switch_onoff_signal_o(external_subsystem_powergate_iso_n[${ext}])
  );

  power_manager_sequence #(.IDLE_VALUE(ISO_IDLE_VALUE), .ONOFF_AT_RESET(ISO_VALUE_AT_RESET))
  power_manager_sequence_external_ram_${ext}_retentive_i (
      .clk_i, .rst_ni,
      .start_off_sequence_i(reg2hw_plat.external_ram_${ext}_retentive.q),
      .start_on_sequence_i (~reg2hw_plat.external_ram_${ext}_retentive.q),
      .switch_ack_i (1'b1),
      .switch_onoff_signal_o(external_subsystem_pwr_ctrl_o[${ext}].retentive_en_n)
  );

% endfor

  // MONITOR (Split between Common and Platform)

  assign hw2reg_common.monitor_power_gate_core.de = 1'b1;
  assign hw2reg_common.monitor_power_gate_core.d = {cpu_subsystem_rst_n, cpu_subsystem_powergate_iso_n, cpu_subsystem_powergate_switch_n};

  assign hw2reg_common.monitor_power_gate_periph.de = 1'b1;
  assign hw2reg_common.monitor_power_gate_periph.d = {peripheral_subsystem_rst_n, peripheral_subsystem_powergate_iso_n, peripheral_subsystem_powergate_switch_n};

% for bank in memory_ss.iter_ram_banks():
  assign hw2reg_plat.monitor_power_gate_ram_block_${bank.name()}.de = 1'b1;
  assign hw2reg_plat.monitor_power_gate_ram_block_${bank.name()}.d = {memory_subsystem_banks_powergate_iso_n[${bank.name()}], memory_subsystem_banks_powergate_switch_n[${bank.name()}]};
% endfor

% for ext in range(external_domains):
  assign hw2reg_plat.monitor_power_gate_external_${ext}.de = 1'b1;
  assign hw2reg_plat.monitor_power_gate_external_${ext}.d = {external_subsystem_rst_n[${ext}], external_subsystem_powergate_iso_n[${ext}], external_subsystem_powergate_switch_n[${ext}]};

% endfor

endmodule : power_manager