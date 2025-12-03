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
// File: tb_sim_ctrl.h
// Author: Flavia Guella
// Date: 03/12/2025

#ifndef TB_SIM_CTRL_H
#define TB_SIM_CTRL_H

//#include "sim_ctrl_extension.h"
//#include "verilated_toplevel.h"
#include "cheshire_utils.hh"
#include "tb_macros.hh"
#include "Vcheshire_testharness.h"
#include "Vcheshire_testharness__Syms.h"
#include "verilated.h"
#include "verilated_fst_c.h"

#include <string>
#include <chrono>

class TbSimCtrl {
 public:
  TbSimCtrl() = default;
  /**
  * Parse command line arguments
  *
  * Process all recognized command-line arguments from argc/argv. If a command
  * line argument implies that we should exit immediately (like --help), sets
  * exit_app. On failure, sets exit_app as well as returning false.
  *
  * @param argc, argv Standard C command line arguments
  * @return Return code, true == ERROR
  */
  bool ParseCLIArguments(int argc, char **argv);
  /**
  * Parse command line arguments
  *
  * Process standard command-line arguments from argc/argv.
  * @param argc, argv Standard C command line arguments
  */ 
  
  void ParseCommandArgs(int argc, char **argv);
  /**
  * Pre-execution setup for the simulation.
  *
  * Load the firmware if boot mode is set to force 
  */
  void PreExec();
  /**
   * Set the top-level design
   */
  void SetTop();
  /**
  * Force the boot sequence if boot mode is set to force
  */
  void ForceBoot();
  /*
  * Run the simulation for a number of cycles
  * @param ncycles Number of cycles to be executed
  */
  void runCycles(unsigned ncycles);

  /**
   * Set the boot mode
   * @param boot_mode Boot mode to be set
   * @return boot mode set
   */
  unsigned int SetBootMode(std::string boot_mode_arg);
  /**
  * Run the simulation
  */
  void Run();
  /**
  * A helper function to execute a standard set of run commands.
  *
  * This function performs the following tasks:
  * 1. Sets up a signal handler to enable tracing to be turned on/off during
  *    a run by sending SIGUSR1 to the process
  * 2. Prints some tracer-related helper messages
  * 3. Runs the simulation
  * 4. Prints some further helper messages and statistics once the simulation
  *    has run to completion
  * @param argc Command line argument count
  * @param argv Command line arguments
  * @return exit value
  */
  unsigned RunSimulation(int argc, char** argv);
  /**
  * Assert the reset signal
  */
  void SetReset();
  
  /**
  * Initialize the Waveform file
  */
  void WavesInit();
  /**
  * Initialize the DUT signals
  */
  void Init();
  
  /**
  * Deassert the reset signal
  */
  void UnsetReset();
  /*
  * Post execution tasks
  * @return exit value
  */
  unsigned PostExec();
  /**
  * Get the wallclock execution time in ms
  */
  unsigned int GetExecutionTimeMs() const;
  /**
  * Print statistics about the simulation run
  */
  void PrintStatistics() const;

  TbLogger logger;
 private:
  Vcheshire_testharness* dut;
  VerilatedFstC* m_trace;
  std::string my_arg_value_;
  CheshireUtils* utils_;
  std::string firmware_;
  unsigned int mem_type_;
  std::string boot_mode_arg_;
  unsigned int boot_mode_;
  bool gen_waves_;
  bool no_err_;
  bool run_all_;
  vluint64_t max_sim_time_;
  vluint64_t sim_cycles_;
  std::chrono::steady_clock::time_point time_begin_;
  std::chrono::steady_clock::time_point time_end_;
};


#endif // TB_SIM_CTRL_H