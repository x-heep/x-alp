#include <stdlib.h>
#include <iostream>


#include "tb_macros.hh"
#include "tb_sim_ctrl.h"



int main (int argc, char** argv, char** env) {

  TbSimCtrl tb_sim_ctrl;

  // Pass CL arguments to Verilator
  Verilated::commandArgs(argc, argv);


  return (tb_sim_ctrl.RunSimulation(argc, argv));

}