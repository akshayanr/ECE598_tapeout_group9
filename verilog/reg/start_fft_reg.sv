//module start_fft_reg
module start_fft_reg (
    input      start_fft_wdata,
    input      clk,
    input      rst_n,
    input      start_fft_wen,
    input      start_fft_ren,
    output reg start_fft_reg,
    output reg start_fft_rdata,
    output reg start_fft_ready
);

    //asynchronous active low.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_fft_reg   <= 0;
            start_fft_rdata <= 0;
            start_fft_ready <= 0;
        end 
        else begin
            //if start_fft_wen
            if (start_fft_wen) begin
                //set the fft reg.
                start_fft_reg   <= start_fft_wdata;
                start_fft_ready <= 0;
            end else begin
                if (start_fft_ren) 
                    begin
                    start_fft_rdata <= start_fft_reg;
                    start_fft_ready  <= 1;
                    end  
                else begin
                    start_fft_rdata <= 0;
                    start_fft_ready  <= 0;
                end
            end
        end
    end

endmodule