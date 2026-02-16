module fft_done_reg (
	input clk,
	input rst_n,
	input core_done, // from core
    output reg fft_done_reg


);
    // note that core_done is active low

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // default state done
            fft_done_reg <= 0;
        end 
        else begin
            // from fft to tell us when computation has finished
            fft_done_reg <= core_done;
        end
    end

endmodule
