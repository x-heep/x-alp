module bootrom_subsystem #(
    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic
) (
    input  reg_req_t reg_req_i,
    output reg_rsp_t reg_rsp_o
);

    import core_v_mcu_pkg::*;

    bootrom #(
        .AddrWidth(32),
        .DataWidth(32)
    ) u_bootrom (
        .clk_i ('0),
        .rst_ni(1'b1),
        .req_i (reg_req_i.valid),
        .addr_i(reg_req_i.addr[31:0]),
        .data_o(reg_rsp_o.rdata)
    );

    assign reg_rsp_o.ready = 1'b1;

endmodule
