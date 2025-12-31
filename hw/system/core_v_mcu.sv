module core_v_mcu (
  input logic clk_i,
  input logic rst_ni
);

  import core_v_mcu_pkg::*;

  // Internal signals
  core_v_mcu_axi_pkg::axi_req_t  bus_req_sig;
  core_v_mcu_axi_pkg::axi_resp_t bus_resp_sig;

  // Instantiate CPU Subsystem
  cpu_subsystem cpu_subsystem_inst (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .boot_addr_i('0),

    // .cvxif_resp_o (),
    // .cvxif_req_i('0),

    .bus_req_o (bus_req_sig),
    .bus_resp_i(bus_resp_sig),

    .irq_i      ('0),
    .time_irq_i ('0),
    .debug_req_i('0)
  );

endmodule
