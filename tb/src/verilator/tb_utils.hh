#ifndef TB_UTILS_H
#define TB_UTILS_H

#include <iostream>
#include <verilated.h>

#define CLK_FREQUENCY_kHz (100*1000)
#define CLK_PERIOD_ps (1000*1000*1000 / CLK_FREQUENCY_kHz)
//#define CLK_PERIOD_RTC_ps (30510) // must be a multiple of CLK_PERIOD_ps/2
#define CLK_PERIOD_RTC_ps (CLK_PERIOD_ps*100)


// Careful, they do not correspond to the values the registers expect
// as SPI and EEPROM are not supported
typedef enum {
  BOOT_MODE_FORCE = 0,
  BOOT_MODE_WAIT_FOR_DEBUGGER = 1,
} boot_mode_t;


// sim cycles
extern vluint64_t sim_cycles;


class TbUtils // declare Calculator class
{

  public: // public members
    TbUtils(); // default constructor
    TbUtils(int argc, char* argv[]);
    // Cmd Line options
    // -----------------
    std::string getCmdOption(int argc, char* argv[], const std::string& option); // get options from cmd lines
    bool get_use_openocd();
    unsigned int extract_memory_type();
    std::string get_firmware();
    unsigned long long get_max_sim_time(bool& run_all);
    std::string get_boot_mode();
    int argc;
    char** argv;


};



#endif