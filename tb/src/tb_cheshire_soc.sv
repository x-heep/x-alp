// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>

module tb_cheshire_soc #(
  /// The selected simulation configuration from the `tb_cheshire_pkg`.
  parameter int unsigned SelectedCfg = 32'd0,
  parameter bit          UseDramSys  = 1'b0,
  parameter bit          UseJtagDPI  = 1'b0
);

  fixture_cheshire_soc #(
    .SelectedCfg  (SelectedCfg),
    .UseDramSys   (UseDramSys),
    .UseJtagDPI   (UseJtagDPI)
  ) fix();

  string      preload_elf;
  string      boot_hex;
  logic [2:0] boot_mode;
  logic [1:0] preload_mode;
  bit [31:0]  exit_code;

  // PARAMETERS
  parameter string VCD_BASENAME = "waves-";
  parameter string VCD_DIR = "logs/";
  int          vcd_mode_opt;  // 0: no dump, 1: unconditional dump, 2: triggered by startup //TODO: add an external trigger mode
  
  initial begin
    // Fetch plusargs or use safe (fail-fast) defaults
    if (!$value$plusargs("BOOTMODE=%d", boot_mode))     boot_mode     = 0;
    if (!$value$plusargs("PRELMODE=%d", preload_mode))  preload_mode  = 0;
    if (!$value$plusargs("BINARY=%s",   preload_elf))   preload_elf   = "";
    if (!$value$plusargs("IMAGE=%s",    boot_hex))      boot_hex      = "";


    // VCD dump
    $value$plusargs("vcd_mode=%d", vcd_mode_opt);
    $display("[CONFIG] VCD dump mode: %0d", vcd_mode_opt);

    // Set boot mode and preload boot image if there is one
    fix.vip.set_boot_mode(boot_mode);
    fix.vip.i2c_eeprom_preload(boot_hex);
    fix.vip.spih_norflash_preload(boot_hex);

    // Wait for reset
    fix.vip.wait_for_reset();

    // Preload in idle mode or wait for completion in autonomous boot
    if (boot_mode == 0) begin
      // Idle boot: preload with the specified mode
      case (preload_mode)
        0: begin      // JTAG
          if (!UseJtagDPI) begin
            fix.vip.jtag_init();
            fix.vip.jtag_elf_run(preload_elf);
            fix.vip.jtag_wait_for_eoc(exit_code);
          end else begin
            // User Serial Link to wait for GDB execution to finish
            fix.vip.slink_wait_for_eoc(exit_code);
          end
        end 1: begin  // Serial Link
          fix.vip.slink_elf_run(preload_elf);
          fix.vip.slink_wait_for_eoc(exit_code);
        end 2: begin  // UART
          fix.vip.uart_debug_elf_run_and_wait(preload_elf, exit_code);
        end default: begin
          $fatal(1, "Unsupported preload mode %d (reserved)!", boot_mode);
        end
      endcase
    end else if (boot_mode == 1) begin
      $fatal(1, "Unsupported boot mode %d (SD Card)!", boot_mode);
    end else if ( boot_mode == 4 ) begin
      // Force boot mode, preload code in DRAM and force execution start
      $display("Force boot mode selected.");
      fix.vip.force_elf_run(preload_elf);
      fix.vip.force_wait_for_eoc(exit_code);
    end else begin
      // Autonomous boot: Only poll return code
      fix.vip.jtag_init();
      fix.vip.jtag_wait_for_eoc(exit_code);
    end

    // Wait for the UART to finish reading the current byte
    wait (fix.vip.uart_reading_byte == 0);

    $finish;
  end




  // --------
  // VCD DUMP
  // --------

  // VCD dump
  typedef enum logic [1:0] {
    IDLE,
    DUMP_INIT,
    WAIT,
    DUMP_OFF
  } fsm_state_t;
  enum int unsigned {
    VCD_MODE_OFF  = 0,  // no dump
    VCD_MODE_ON   = 1,  // unconditional dump
    VCD_MODE_TRIG = 2   // triggered dump
  } vcd_mode_e;
  fsm_state_t curr_state, next_state;
  logic vcd_trigger;
  bit   vcd_cnt_en;
  string vcd_filename_d, vcd_filename_q;
  int unsigned vcd_cnt;


  // System clock and reset
  logic        sys_clk;
  logic        sys_rst_n;

  assign sys_clk   = fix.dut.clk_i;
  assign sys_rst_n = fix.dut.rst_ni;




  // VCD dump FSM control signals
  // set after preload of code
  assign vcd_trigger = fix.dut.i_regs.scratch_2_qs;



  // VCD dump FSM
  // ------------
  // FSM state progression
  always_comb begin : fsm_state_prog
    // Default values
    vcd_cnt_en     = 1'b0;
    vcd_filename_d = "";

    // State progression
    case (curr_state)
      IDLE: begin
        case (vcd_mode_opt)
          VCD_MODE_ON: next_state = DUMP_INIT;  // unconditional dump
          VCD_MODE_TRIG: begin  // triggered dump
            if (vcd_trigger) begin
              next_state = DUMP_INIT;
            end else begin
              next_state = IDLE;
            end
          end
          default:     next_state = IDLE;  // no dump
        endcase
      end
      DUMP_INIT: begin
        next_state     = WAIT;
        // Increment VCD sequence counter
        vcd_cnt_en     = 1'b1;
        // Create VCD file and start dumping
        vcd_filename_d = {VCD_DIR, VCD_BASENAME, $sformatf("%0d", vcd_cnt), ".vcd"};
        // NOTE: the following system tasks are specific to QuestaSim and not
        // part of the Verilog IEEE1364 standard, so may be not portable to
        // other simulators
`ifndef VCS
        $fdumpfile(vcd_filename_d);
        $dumpvars(0, fix.dut);
`endif
        $display("[%t] VCD file initialized: %s", $time, vcd_filename_d);
        $display("[%t] VCD dump ON", $time);
      end
      WAIT: begin
        case (vcd_mode_opt)
          VCD_MODE_ON: begin  // unconditional dump
            next_state = WAIT;
          end
          VCD_MODE_TRIG: begin  // triggered dump
            if (vcd_trigger) begin
              next_state = WAIT;
            end else begin
              next_state = DUMP_OFF;
            end
          end
          default: next_state = IDLE;  // no dump
        endcase
      end
      DUMP_OFF: begin
        next_state = IDLE;
`ifndef VCS
        $fdumpoff(vcd_filename_q);
`endif
        $display("[%t] VCD dump OFF", $time);
      end
      default: next_state = IDLE;
    endcase
  end

  // FSM state register
  always_ff @(posedge sys_clk or negedge sys_rst_n) begin : fsm_state_reg
    if (!sys_rst_n) curr_state <= IDLE;
    else curr_state <= next_state;
  end

  // VCD sequence counter
  always_ff @(posedge sys_clk or negedge sys_rst_n) begin : vcd_cnt_reg
    if (!sys_rst_n) vcd_cnt <= 0;
    else if (vcd_cnt_en) vcd_cnt <= vcd_cnt + 1;
  end

`ifndef VCS
  // VCD filename register
  always_ff @(posedge sys_clk) begin : vcd_filename_reg
    if (vcd_cnt_en) vcd_filename_q <= vcd_filename_d;
  end
`endif










endmodule
