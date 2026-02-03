module xilinx_x_alp_wrapper
(
    // Clock and Reset
    input logic clk_i,
    input logic rst_ni,

    // UART IO
    output logic uart_tx_o,
    input  logic uart_rx_i,

    // JTAG Interface
    input  logic jtag_tck_i,
    input  logic jtag_tms_i,
    input  logic jtag_trst_ni,
    input  logic jtag_tdi_i,
    output logic jtag_tdo_o,
    output logic jtag_tdo_oe_o,

    // Test mode
    input logic test_mode_i,

    // Exit interface
    output logic        exit_valid_o,
    output logic        exit_value_o,

    output logic rst_led_o,
    output logic clk_led_o
);

    logic [31:0] exit_value;

    logic clk_gen;
    logic rst_n;

    localparam CLK_LED_COUNT_LENGTH = 26;
  logic [CLK_LED_COUNT_LENGTH - 1:0] clk_count;


      // reset LED for debugging
  assign rst_led_o = rst_n;
  assign rst_n = ~rst_i;
    localparam int CLK_LED_COUNT_LENGTH = 27;

  // counter to blink an LED
  assign clk_led_o = clk_count[CLK_LED_COUNT_LENGTH-1];

  always_ff @(posedge clk_gen or negedge rst_n) begin : clk_count_process
    if (!rst_n) begin
      clk_count <= '0;
    end else begin
      clk_count <= clk_count + 1;
    end
  end

      xilinx_clk_wizard_wrapper xilinx_clk_wizard_wrapper_i (
      .clk_125MHz(clk_i),
      .clk_out1_0(clk_gen)
  );

    x_alp u_x_alp (

    // Clock and Reset
    .clk_i(clk_gen),
    .rst_ni(rst_n),

    // UART IO
    .uart_tx_o(uart_tx_o),
    .uart_rx_i(uart_rx_i),

    // JTAG Interface
    .jtag_tck_i(jtag_tck_i),
    .jtag_tms_i(jtag_tms_i),
    .jtag_trst_ni(jtag_trst_ni),
    .jtag_tdi_i(jtag_tdi_i),
    .jtag_tdo_o(jtag_tdo_o),
    .jtag_tdo_oe_o(jtag_tdo_oe_o),

    // Test mode
    .test_mode_i(test_mode_i),

    // Exit interface
    .exit_valid_o(exit_valid_o),
    .exit_value_o(exit_value)

    );

    assign exit_value_o = exit_value[0];


endmodule