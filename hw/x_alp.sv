module x_alp (

  // Clock and Reset
  input logic clk_i,
  input logic rst_ni

);

  core_v_mcu u_core_v_mcu (
    .clk_i (clk_i),
    .rst_ni(rst_ni)
  );

endmodule : x_alp
