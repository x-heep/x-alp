module x_alp (

    // Clock and Reset
    input logic clk_i,
    input logic rst_ni

);

    core_v_mcu u_core_v_mcu (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .boot_select_i(1'b0),
        .exit_valid_o (),
        .exit_value_o (),
        .uart_rx_i    (1'b0),
        .uart_tx_o    ()
    );

endmodule : x_alp
