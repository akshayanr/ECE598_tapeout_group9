module reset_fft_reg (
    input      reset_fft_wdata,
    input      clk,
    input      rst_n,
    input      reset_fft_wen,
    input      reset_fft_ren,
    output reg reset_fft_reg,
    output reg reset_fft_rdata,
    output reg reset_fft_ready
);

    //asynchronous reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_fft_reg   <= 1;
            reset_fft_rdata <= 0;
            reset_fft_ready <= 0;
        end 
        //if write to reset, then write to reset.
        else begin
            if (reset_fft_wen) begin
                reset_fft_reg   <= reset_fft_wdata;
                reset_fft_ready <= 0;
            end else begin
                if (reset_fft_ren) 
                    begin
                    reset_fft_rdata <= reset_fft_reg;
                    reset_fft_ready  <= 1;
                    end  
                else begin
                    reset_fft_rdata <= 0;
                    reset_fft_ready  <= 0;
                end
            end
        end
    end

endmodule