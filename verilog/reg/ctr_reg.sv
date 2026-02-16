module ctr_reg (
    input      [16:0] ctr1_wdata,
    input      [14:0] ctr2_wdata,
    input             clk,
    input             rst_n,
    input             ctr_wen,
    input             ctr_ren,
    output     reg [16:0] ctr1,
    output     reg [14:0] ctr2,
    output     reg [16:0] ctr1_rdata,
    output     reg [14:0] ctr2_rdata,

// Handshake bit ctr_read 
    output     reg        ctr_ready
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctr1         <= 17'h0;
            ctr2         <= 15'h0;
            ctr1_rdata   <= 17'h0;
            ctr2_rdata   <= 15'h0;
            ctr_ready    <= 0;
            end 
        else begin
                if (ctr_wen) 
                    begin
                    ctr1      <= ctr1_wdata;
                    ctr2      <= ctr2_wdata;
                    ctr_ready <= 0;
                    end 
                else begin 
                     if (ctr_ren) 
                          begin
                          ctr1_rdata <= ctr1;
                          ctr2_rdata <= ctr2;
                          ctr_ready  <= 1;
                          end  
                     else begin
                          ctr1_rdata <= 0;
                          ctr2_rdata <= 0;
                          ctr_ready  <= 0;
                     end
                     end
              end
    end

endmodule
