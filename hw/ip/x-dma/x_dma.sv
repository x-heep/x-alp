module x_dma #(
        parameter type reg_req_t = logic,
        parameter type reg_rsp_t = logic
)
    (
        input logic clk_i,
        input logic rst_ni,

        input  reg_req_t reg_req_i,
        output reg_rsp_t reg_rsp_o 
    );

    // import x_dma_reg_pkg::*;
    // x_dma_reg2hw_t reg2hw; //software to hardware register interface
    // x_dma_hw2reg_t hw2reg; //hardware to software register interface
    always_ff @( clk_i ) begin : handhsake
        if (rst_ni == 1'b0) begin
            reg_rsp_o <= '0;
        end else begin
            if (reg_req_i.valid) begin
                // Process the register request and generate a response
                reg_rsp_o.valid <= 1'b1;
                reg_rsp_o.data  <= 'hDEADBEEF; // Example response data
            end else begin
                reg_rsp_o.valid <= 1'b0;
            end
        end
        
    end


endmodule;
