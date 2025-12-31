module cpu_subsystem (
  input logic clk_i,
  input logic rst_ni,

  input logic [63:0] boot_addr_i,

  // CVXIF request
  // output core_v_mcu_pkg::cvxif_req_t cvxif_req_o,
  // CVXIF response
  // input core_v_mcu_pkg::cvxif_resp_t cvxif_resp_i,

  // AXI bus request
  output core_v_mcu_axi_pkg::axi_req_t  bus_req_o,
  // AXI bus response
  input  core_v_mcu_axi_pkg::axi_resp_t bus_resp_i,

  // Level sensitive (async) interrupts
  input logic [1:0] irq_i,
  // Timer (async) interrupt
  input logic       time_irq_i,
  // Debug (async) request
  input logic       debug_req_i

);

  cva6 #(
    .noc_req_t (core_v_mcu_axi_pkg::axi_req_t),
    .noc_resp_t(core_v_mcu_axi_pkg::axi_resp_t)
  ) cpu_inst (
    .clk_i        (clk_i),
    // Asynchronous reset active low
    .rst_ni       (rst_ni),
    // Reset boot address
    .boot_addr_i  (boot_addr_i),
    // Hard ID reflected as CSR
    .hart_id_i    ('0),
    // Level sensitive (async) interrupts
    .irq_i        (irq_i),
    // Inter-processor (async) interrupt
    .ipi_i        ('0),
    // Timer (async) interrupt
    .time_irq_i   (time_irq_i),
    // Debug (async) request
    .debug_req_i  (debug_req_i),
    // Probes to build RVFI, can be left open when not used - RVFI
    .rvfi_probes_o(),
    // CVXIF request
    // .cvxif_req_o  (cvxif_req_o),
    // CVXIF response
    // .cvxif_resp_i (cvxif_resp_i),
    // noc request, can be AXI or OpenPiton
    .noc_req_o    (bus_req_o),
    // noc response, can be AXI or OpenPiton
    .noc_resp_i   (bus_resp_i)
  );

endmodule
