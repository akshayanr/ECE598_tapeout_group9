module fft_done_reg (
	input clk,
	input rst_n,
	input core_done, // from core
    output reg fft_done_reg


);
    //core done is no longer active low. it's active high.
    //TODO: need to make that this is consistent with the rest of the core.
    //we might need to turn on start ftt right after because it transitions.
    //so before start done and reg will be read
    

    //to different types of sram reads; input debug, and output read.
    //start -> go to working -> done.

    //sream read. 
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
