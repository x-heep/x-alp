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
// File: tb_utils.cpp
// Author: Flavia Guella
// Date: 06/09/2025
// Description: Command line options for X-ALP testbench
// From: https://github.com/x-heep/x-heep

#include "tb_utils.hh"
#include "tb_macros.hh"
#include <iostream>
#include <string>

TbUtils::TbUtils() // define default constructor
{}

TbUtils::TbUtils(int argc, char *argv[]) // define default constructor
{
  this->argc = argc;
  this->argv = argv;
}

std::string TbUtils::getCmdOption(int argc, char *argv[], const std::string &option) {
  std::string cmd;
  for (int i = 0; i < argc; ++i) {
    std::string arg = argv[i];
    size_t arg_size = arg.length();
    size_t option_size = option.length();

    if (arg.find(option) == 0) { cmd = arg.substr(option_size, arg_size - option_size); }
  }
  return cmd;
}

bool TbUtils::get_use_openocd() {

  std::string arg_openocd = this->getCmdOption(this->argc, this->argv, "+openOCD=");
  ;

  bool use_openocd = false;

  if (arg_openocd.empty()) {
    std::cout << "[TESTBENCH]: No OpenOCD is used" << std::endl;
  } else {
    std::cout << "[TESTBENCH]: OpenOCD is used" << std::endl;
    use_openocd = true;
  }

  return use_openocd;
}

std::string TbUtils::get_firmware() {

  std::string firmware = this->getCmdOption(this->argc, this->argv, "+BINARY=");

  if (firmware.empty()) {
    std::cout << "[TESTBENCH]: No firmware  specified" << std::endl;
  } else {
    std::cout << "[TESTBENCH]: loading firmware  " << firmware << std::endl;
  }

  return firmware;
}

unsigned int TbUtils::extract_memory_type() {
  std::string firmware = this->getCmdOption(this->argc, this->argv, "+BINARY=");

  // Extract the filename from the path
  size_t last_slash = firmware.find_last_of("/\\");
  std::string filename = (last_slash == std::string::npos) ? firmware : firmware.substr(last_slash + 1);

  // Now find the part before ".memh"
  size_t memh_pos = filename.rfind(".memh");
  size_t elf_pos = filename.rfind(".elf");
  if (memh_pos == std::string::npos && elf_pos == std::string::npos) {
    std::cerr << "[ERROR]: File does not contain '.memh' or '.elf'" << std::endl;
    return EXIT_FAILURE;
  }
  if (memh_pos == std::string::npos) { memh_pos = elf_pos; }

  // From here, go backwards and find the previous dot
  size_t dot_before = filename.rfind('.', memh_pos - 1);
  if (dot_before == std::string::npos) {
    std::cerr << "[ERROR]: Unexpected filename format (no dot before '.memh')" << std::endl;
    return EXIT_FAILURE;
  }

  // Extract the part between the two dots
  std::string memory_type = filename.substr(dot_before + 1, memh_pos - dot_before - 1);
  unsigned int mem_type;
  if (memory_type != "dram" && memory_type != "spm") {
    std::cerr << "[ERROR]: Unsupported memory type '" << memory_type << "'. Supported types are 'dram' and 'spm'."
              << std::endl;
    return EXIT_FAILURE;
  } else if (memory_type == "dram") {
    std::cout << "[TESTBENCH]: Using DRAM as memory type" << std::endl;
    mem_type = 0; // DRAM
  } else if (memory_type == "spm") {
    std::cout << "[TESTBENCH]: Using SPM as memory type" << std::endl;
    mem_type = 1; // SPM
  }

  return mem_type;
}

unsigned long long TbUtils::get_max_sim_time(bool &run_all) {

  std::string arg_max_sim_time = this->getCmdOption(this->argc, this->argv, "+MAX_CYCLES=");
  unsigned long long max_sim_time;

  max_sim_time = 0;
  if (arg_max_sim_time.empty()) {
    std::cout << "[TESTBENCH]: No Max time specified" << std::endl;
    run_all = true;
  } else {
    size_t u;
    max_sim_time = stoull(arg_max_sim_time, &u);
    if (u == arg_max_sim_time.length())
      max_sim_time *= CLK_PERIOD_ps; // no suffix: clock cycles
    else if (arg_max_sim_time[u] == 'p')
      max_sim_time *= 1; // "p" or "ps" suffix: picoseconds
    else if (arg_max_sim_time[u] == 'n')
      max_sim_time *= 1000; // "n" or "ns" suffix: nanoseconds
    else if (arg_max_sim_time[u] == 'u')
      max_sim_time *= 1000000; // "u" or "us" suffix: microseconds
    else if (arg_max_sim_time[u] == 'm')
      max_sim_time *= 1000000000; // "m" or "ms" suffix: milliseconds
    else if (arg_max_sim_time[u] == 's')
      max_sim_time *= 1000000000000; // "s" suffix: seconds
    else {
      std::cout << "[TESTBENCH]: ERROR: Unsupported suffix '" << arg_max_sim_time.substr(u)
                << "' for +MAX_CYCLES=" << std::endl;
      exit(EXIT_FAILURE);
    }
    std::cout << "[TESTBENCH]: Max sim time is " << (max_sim_time / CLK_PERIOD_ps) << " clock cycles" << std::endl;
  }

  return max_sim_time;
}

std::string TbUtils::get_boot_mode() {
  std::string arg_boot_mode = this->getCmdOption(this->argc, this->argv, "+BOOTMODE=");
  if (arg_boot_mode.empty()) {
    std::cout << "[TESTBENCH]: No Boot Option specified, using force boot" << std::endl;
    arg_boot_mode = "force";
  } else {
    if (arg_boot_mode == "force") {
      std::cout << "[TESTBENCH]: Force boot from testbench" << std::endl;
    } else if (arg_boot_mode == "jtag") {
      std::cout << "[TESTBENCH]: Autonomous boot using JTAG and GDB" << std::endl;
    } else {
      std::cerr << "[TESTBENCH]: Wrong Boot Option specified, supported "
                   "options are ( force, jtag)"
                << std::endl;
      std::cerr << "[TESTBENCH]: Defaulting to force boot" << std::endl;
      arg_boot_mode = "force";
    }
    return arg_boot_mode;
  }

  return arg_boot_mode;
}
