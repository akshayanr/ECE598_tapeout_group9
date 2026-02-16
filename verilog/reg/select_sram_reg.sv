module select_sram_reg (
	input clk,
	input rst_n,
	input new_stage_trigger,
    input status,
    output reg select_sram_reg

);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // bit 0 for SRAM A
            select_sram_reg <= 0;
        end 
        else begin
            if (new_stage_trigger && status) begin
                // switch SRAM to read from
                select_sram_reg <= ~select_sram_reg;
            end else begin
                select_sram_reg <= select_sram_reg;
            end
        end
    end

endmodule
