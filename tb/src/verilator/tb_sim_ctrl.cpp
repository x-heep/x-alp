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
// File: tb_sim_ctrl.cpp
// Author: Flavia Guella
// Date: 03/12/2025

#include "tb_sim_ctrl.h"
#include "tb_elfloader.hh"
#include <getopt.h>

void TbSimCtrl::runCycles(unsigned ncycles) {
  for (unsigned i = 0; i < 2 * ncycles; i++) {
    sim_cycles_ += CLK_PERIOD_ps / 2;
    dut->clk_i ^= 1;
    if (sim_cycles_ % (CLK_PERIOD_RTC_ps / 2) == 0) { dut->rtc_i ^= 1; }
    dut->eval();
    if (gen_waves_) { m_trace->dump(sim_cycles_); }
  }
}

void TbSimCtrl::ParseCommandArgs(int argc, char **argv) {
  const struct option long_options[] = {{"help", no_argument, NULL, 'h'},
                                        {"log_level", required_argument, NULL, 'l'},
                                        {"trace", required_argument, NULL, 't'},
                                        {"no_err", required_argument, NULL, 'q'},
                                        {NULL, 0, NULL, 0}};

  while (1) {
    int c = getopt_long(argc, argv, ":c:th", long_options, nullptr);
    if (c == -1) { break; }

    // Disable error reporting by getopt
    opterr = 0;
    switch (c) {
    case 'h':
      printf("Usage: %s [OPTIONS]\n", argv[0]);
      printf("Options:\n");
      printf("  -h, --help\t\t\tPrint this help message\n");
      printf("  -l, --log_level=LOG_LEVEL\tSet the log level\n");
      printf("  -t, --trace=[true/false]\t\tGenerate waveforms\n");
      printf("  -q, --no_err=[true/false]\t\t\tAlways return 0\n");
      exit(0);
      break;
    case 'l':
      logger.setLogLvl(optarg);
      break;
    case 't':
      if (strcmp(optarg, "1") == 0 || strcmp(optarg, "true") == 0) { gen_waves_ = true; }
      break;
    case 'q':
      if (strcmp(optarg, "1") == 0 || strcmp(optarg, "true") == 0) { no_err_ = true; }
      break;
    default:
      break;
    }
  }
}

unsigned int TbSimCtrl::SetBootMode(std::string boot_mode_arg) {
  unsigned int boot_mode = BOOT_MODE_FORCE;

  if (boot_mode_arg.empty()) {
    boot_mode = BOOT_MODE_FORCE;
  } else {
    if (boot_mode_arg == "force") {
      boot_mode = BOOT_MODE_FORCE;
    } else if (boot_mode_arg == "jtag") {
      boot_mode = BOOT_MODE_WAIT_FOR_DEBUGGER;
    } else {
      boot_mode = BOOT_MODE_FORCE;
    }
  }

  return boot_mode;
}

bool TbSimCtrl::ParseCLIArguments(int argc, char **argv) {
  run_all_ = false;

  bool exit_app = false;

  utils_ = new TbUtils(argc, argv);
  firmware_ = utils_->get_firmware();
  mem_type_ = utils_->extract_memory_type();
  boot_mode_arg_ = utils_->get_boot_mode();
  max_sim_time_ = utils_->get_max_sim_time(run_all_);

  boot_mode_ = SetBootMode(boot_mode_arg_);
  // TODO: Exit if boot mode is invalid
  switch (boot_mode_) {
  case BOOT_MODE_FORCE:
    break;
  case BOOT_MODE_WAIT_FOR_DEBUGGER:
    break;
  default:
    TB_ERR("Unsupported boot mode — exiting");
    exit_app = true;
    break;
  }
  return exit_app;
}

// TODO: use a return value for failure
void TbSimCtrl::SetTop() {
  dut = new Vtestharness;
  svSetScope(svGetScopeFromName("TOP.testharness"));
  svScope scope = svGetScope();
  if (!scope) {
    TB_ERR("svGetScope failed — exiting");
    exit(EXIT_FAILURE);
  }
}

void TbSimCtrl::WavesInit() {
  m_trace = new VerilatedFstC;
  dut->trace(m_trace, 99);
  m_trace->open("waveform.fst");
  TB_LOG(LOG_MEDIUM, "Waveform tracing enabled → waveform.fst");
}
void TbSimCtrl::Init() {
  // Initialize static variable
  sim_cycles_ = 0;
  dut->clk_i = 0;
  dut->rst_ni = 1;
  dut->rtc_i = 0;
  dut->jtag_tck_i = 0;
  dut->jtag_tms_i = 0;
  dut->jtag_trst_ni = 0;
  dut->jtag_tdi_i = 0;
  dut->boot_mode_i = boot_mode_;
  dut->sim_jtag_enable_i = 0;
  // dut->test_mode_i          = 0; // unsupported test mode
  dut->eval();
  if (gen_waves_) { m_trace->dump(sim_cycles_); }
  runCycles(5);
}

void TbSimCtrl::SetReset() {
  dut->rst_ni = 0;
  runCycles(10);
  TB_LOG(LOG_MEDIUM, "Reset asserted");
}

void TbSimCtrl::UnsetReset() {
  dut->rst_ni = 1;
  TB_LOG(LOG_MEDIUM, "Reset released — simulation running");
  runCycles(5);
}

void TbSimCtrl::PreExec() {
  TbElfLoader *elf_loader = new TbElfLoader();
  // Section chunk length
  long long unsigned SectionChunkLength = 0;

  dut->tb_get_section_chunk_length(&SectionChunkLength);
  TB_LOG(LOG_LOW, "Section chunk length %lu", SectionChunkLength);
  long long sec_addr = 0;
  long long sec_len = 0;
  long long chunk_len = 0;
  char bf[2048] = {0};
  // If boot mode is force, load the firmware
  if (boot_mode_ == BOOT_MODE_FORCE) {
    if (elf_loader->read_elf(firmware_.c_str())) {
      TB_ERR("Failed to load elf %s", firmware_);
      exit(EXIT_FAILURE);
    }
    sec_addr = 0;
    sec_len = 0;
    // Get all sections in the elf file
    while (elf_loader->get_section(&sec_addr, &sec_len)) {
      TB_LOG(LOG_LOW, "Loading section @ 0x%lx len %lu", sec_addr, sec_len);
      for (long long i = 0; i < sec_len; i = i + SectionChunkLength) {
        memset(bf, 0, SectionChunkLength);
        // Read section into chunks
        // Check if last chunk
        chunk_len = (SectionChunkLength < (sec_len - i)) ? SectionChunkLength : (sec_len - i);
        if (elf_loader->read_section_chunk(sec_addr, i, bf, chunk_len)) {
          TB_ERR("Failed to read ELF section!");
          exit(EXIT_FAILURE);
        }
        // Write chunk to memory
        dut->tb_loadChunk(mem_type_, sec_addr + i, bf, chunk_len);
      }
    }
    // runCycles(1, top(), m_trace);
    TB_LOG(LOG_MEDIUM, "Memory Loaded");
  } else if (boot_mode_ == BOOT_MODE_WAIT_FOR_DEBUGGER) {
    if (elf_loader->read_elf(firmware_.c_str())) {
      TB_ERR("Failed to load elf %s", firmware_);
      exit(EXIT_FAILURE);
    }
    sec_addr = 0;
    sec_len = 0;
    while (elf_loader->get_section(&sec_addr, &sec_len)) {
      TB_LOG(LOG_LOW, "Loading section @ 0x%lx len %lu", sec_addr, sec_len);
      for (long long i = 0; i < sec_len; i = i + SectionChunkLength) {
        memset(bf, 0, SectionChunkLength);
        chunk_len = (SectionChunkLength < (sec_len - i)) ? SectionChunkLength : (sec_len - i);
        if (elf_loader->read_section_chunk(sec_addr, i, bf, chunk_len)) {
          TB_ERR("Failed to read ELF section!");
          exit(EXIT_FAILURE);
        }
        dut->tb_loadChunk(mem_type_, sec_addr + i, bf, chunk_len);
      }
    }
    TB_LOG(LOG_MEDIUM, "Memory pre-loaded; connect GDB to control execution.");
    dut->sim_jtag_enable_i = 1;
  }
}

void TbSimCtrl::ForceBoot() {
  // Force boot, write signals
  // -------------------------
  // TODO: move in a separate function outside
  if (boot_mode_ == BOOT_MODE_FORCE) {
    long long unsigned entry_point;
    dut->tb_get_entry_address(mem_type_,
                              &entry_point); // TODO: make it configurable
    unsigned req_accepted = 0;
    // dut->tb_write_entry_address(entry_point);
    runCycles(1);
    dut->tb_preload_force();
    runCycles(1);
    TB_LOG(LOG_MEDIUM, "Wrote launch signal and entry point: @ %lu", sim_cycles_);
    runCycles(2);
    // Release signals
    // dut->tb_release_request();
  }
}

void TbSimCtrl::Run() {
  // Run simulation
  if (run_all_ == false) {
    while (dut->exit_valid_o != 1 && sim_cycles_ < max_sim_time_) { runCycles(100); }
  } else {
    while (dut->exit_valid_o != 1) { runCycles(100); }
  }
}

unsigned TbSimCtrl::PostExec() {
  unsigned exit_val;
  // Set exit value
  if (dut->exit_valid_o == 1) {
    if (dut->exit_value_o == 0)
      TB_SUCCESS(LOG_MEDIUM, "Exit code: %d", dut->exit_value_o);
    else
      TB_WARN("Exit code: %d", dut->exit_value_o);
    exit_val = dut->exit_value_o;
  } else {
    TB_WARN("Simulation ended without exit signal (timeout or JTAG mode)");
    exit_val = 0;
  }
  // Close trace

  if (gen_waves_) {
    m_trace->close();
    delete m_trace;
    m_trace = nullptr;
  }
  // Print statistics
  PrintStatistics();
  // Free memory
  delete dut;
  delete utils_;

  return exit_val;
}

unsigned int TbSimCtrl::GetExecutionTimeMs() const {
  return std::chrono::duration_cast<std::chrono::milliseconds>(time_end_ - time_begin_).count();
}

void TbSimCtrl::PrintStatistics() const {
  double speed_hz = (sim_cycles_ / CLK_PERIOD_ps) / (GetExecutionTimeMs() / 1000.0);
  double speed_khz = speed_hz / 1000.0;
  unsigned long long cycles = sim_cycles_ / CLK_PERIOD_ps;
  double wall_s = GetExecutionTimeMs() / 1000.0;

  printf("\n\033[1m  %-18s %llu cycles\033[0m\n", "Executed:", cycles);
  printf("  %-18s %.2f s\n", "Wall time:", wall_s);
  printf("  %-18s %.1f kHz\n\n", "Sim speed:", speed_khz);
}

unsigned TbSimCtrl::RunSimulation(int argc, char **argv) {
  unsigned exit_value;
  bool exit_app = false;
  gen_waves_ = false;
  no_err_ = false;
  VerilatedContext *cntx = new VerilatedContext;
  cntx->commandArgs(argc, argv);
  // Pass the simulation context to the logger
  logger.setSimContext(cntx);

  printf("\033[1;36m\n  X-ALP Verilator Simulation\033[0m\n\n");
  ParseCommandArgs(argc, argv);
  ::logger.setLogLvl(logger.getLogLvl());
  exit_app = ParseCLIArguments(argc, argv);
  if (exit_app) { return exit_app; }
  SetTop();
  if (gen_waves_) {
    Verilated::traceEverOn(true);
    WavesInit();
  }
  Init();
  PreExec();
  SetReset();
  UnsetReset();
  time_begin_ = std::chrono::steady_clock::now();
  if (boot_mode_ == BOOT_MODE_FORCE) { ForceBoot(); }
  Run();
  time_end_ = std::chrono::steady_clock::now();
  exit_value = PostExec();
  if (no_err_) { exit_value = 0; }
  return exit_value;
}
