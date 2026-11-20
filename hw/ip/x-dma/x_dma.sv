module x_dma #(
    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic
) (
    input logic clk_i,
    input logic rst_ni,

    input  reg_req_t reg_req_i,
    output reg_rsp_t reg_rsp_o
);

    // import x_dma_reg_pkg::*;
    // x_dma_reg2hw_t reg2hw; //software to hardware register interface
    // x_dma_hw2reg_t hw2reg; //hardware to software register interface
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            //reg_rsp_o <= '0;
        end else begin
        end
    end
    assign reg_rsp_o.ready = '1;  //ready signal for software to hardware register interface
    assign reg_rsp_o.valid = '1;  //valid signal for software to hardware register interface
    //assign reg_rsp_o.addr = reg_req_i.addr; //addr signal for software to hardware register interface
    assign reg_rsp_o.data = reg_req_i.data; //data signal for software to hardware register interface
    // assign reg_rsp_o.data = reg_req_i.data; //data signal for software to hardware register interface


endmodule
;
