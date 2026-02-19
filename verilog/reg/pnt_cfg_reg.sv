//changing point config reg to be 3 bits to be consistent with fft implementation.
module pnt_cfg_reg (
    input      [2:0]  pnt_cfg_wdata,
    input             clk,
    input             rst_n,
    input             pnt_cfg_wen,
    input             pnt_cfg_ren,
    output  reg [2:0] pnt_cfg_reg,
    output  reg [2:0] pnt_cfg_rdata,
    output     reg        pnt_cfg_ready
);

    //asynchronous reset again
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pnt_cfg_reg       <= 3'd0;
            pnt_cfg_rdata   <= 11'h0;
            pnt_cfg_ready    <= 0;
            end 
        else begin
            if (pnt_cfg_wen) 
                begin
                // case(pnt_cfg_wdata)
                //     3'b000: pnt_cfg_reg <= 11'd8;
                //     3'b001: pnt_cfg_reg <= 11'd16;
                //     3'b010: pnt_cfg_reg <= 11'd32;
                //     3'b011: pnt_cfg_reg <= 11'd64;
                //     3'b100: pnt_cfg_reg <= 11'd128;
                //     3'b101: pnt_cfg_reg <= 11'd256;
                //     3'b110: pnt_cfg_reg <= 11'd512;
                //     3'b111: pnt_cfg_reg <= 11'd1024;

                //     default: pnt_cfg_reg <= 11'd8;
                // endcase
                pnt_cfg_reg <= pnt_cfg_wdata;
                pnt_cfg_ready <= 0;
                end 
            else begin 
                if (pnt_cfg_ren) 
                    begin
                    pnt_cfg_rdata <= pnt_cfg_reg;
                    pnt_cfg_ready  <= 1;
                    end  
                else begin
                    pnt_cfg_rdata <= 3'd0;
                    pnt_cfg_ready  <= 0;
                end
            end
        end
    end

endmodule
