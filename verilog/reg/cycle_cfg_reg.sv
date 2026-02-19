//the users could set the cycle count
//like config -> going to stay the same until you change.
module cycle_cfg_reg (
    input      [10:0]  cycle_cfg_wdata,
    input             clk,
    input             rst_n,
    input             cycle_cfg_wen,
    input             cycle_cfg_ren,
    output  reg [10:0] cycle_cfg_reg,
    output  reg [10:0] cycle_cfg_rdata,
    output     reg    cycle_cfg_ready
);

    //asynchronous reset again
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_cfg_reg       <= 11'd2047;
            cycle_cfg_rdata   <= 11'h0;
            cycle_cfg_ready    <= 0;
            end 
        else begin
            if (cycle_cfg_wen) 
                begin
                cycle_cfg_reg <= cycle_cfg_wdata;
                cycle_cfg_ready <= 0;
                end 
            else begin 
                if (cycle_cfg_ren) 
                    begin
                    cycle_cfg_rdata <= cycle_cfg_reg;
                    cycle_cfg_ready  <= 1;
                    end  
                else begin
                    cycle_cfg_rdata <= 11'd0;
                    cycle_cfg_ready  <= 0;
                end
            end
        end
    end

endmodule
