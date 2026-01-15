package core_v_mcu_pkg;

  //-----------
  // BUS Config
  //-----------
  localparam int unsigned NumMasters = 2; // just core and ext for now

  localparam int unsigned NumAxiSlaves = 1; // ext (or non for now)
  localparam int unsigned NumRegSlaves = 2; // UART + ext only for now
  localparam int unsigned NumSlaves = NumAxiSlaves + NumRegSlaves;


endpackage : core_v_mcu_pkg
