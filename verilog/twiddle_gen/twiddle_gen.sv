module twiddle_gen(
    input clk,
    input i_resetn, 

    input [2:0] i_point_configuration, 
    input [9:0] i_stride,
//    input i_working,
    input i_group_done, 
    input i_new_stage_trigger,
//    input i_fft_done,
    input i_data_valid,
    
    output [8:0] o_butterfly1_twiddle,
    output [8:0] o_butterfly2_twiddle, 
    output [8:0] o_butterfly3_twiddle, 
    output [8:0] o_butterfly4_twiddle
);

    logic [8:0] twiddle_offset1;
    logic [8:0] twiddle_offset2; 
    logic [8:0] twiddle_offset3; 
    logic [8:0] twiddle_offset4; 
    logic [8:0] reset_twiddle; 

    logic [8:0] twiddle_idx_increment;
    

    logic stride_greater_than_2; 
    logic stride_equal_2;

    assign stride_greater_than_2 = (i_stride > 2);
    assign stride_equal_2 = (i_stride == 2);


    always_comb begin
        case(i_point_configuration)
            3'b000: reset_twiddle = 128;
            3'b001: reset_twiddle = 64;
            3'b010: reset_twiddle = 32;
            3'b011: reset_twiddle = 16;
            3'b100: reset_twiddle = 8;
            3'b101: reset_twiddle = 4;
            3'b110: reset_twiddle = 2;
            3'b111: reset_twiddle = 1;
        endcase
    end
    
    assign twiddle_offset2 = twiddle_offset1 + twiddle_idx_increment;
    assign twiddle_offset3 = twiddle_offset1 + (twiddle_idx_increment * 2);
    assign twiddle_offset4 = twiddle_offset1 + (twiddle_idx_increment * 3);

    assign o_butterfly1_twiddle = twiddle_offset1;
    assign o_butterfly2_twiddle = (stride_greater_than_2 || stride_equal_2) ? twiddle_offset2 : twiddle_offset1;
    assign o_butterfly3_twiddle = stride_greater_than_2 ? twiddle_offset3 : twiddle_offset1; 
    assign o_butterfly4_twiddle = stride_greater_than_2 ? twiddle_offset4 : (stride_equal_2 ? twiddle_offset2 : twiddle_offset1);

    always_ff @(posedge clk or negedge i_resetn) begin 
        if(!i_resetn) begin
            twiddle_idx_increment <= reset_twiddle;
            twiddle_offset1 <= 0; 
        end else begin
            
            if (i_new_stage_trigger) begin
                twiddle_idx_increment <= twiddle_idx_increment << 1;
            end else begin
                twiddle_idx_increment <= twiddle_idx_increment;
            end

            if(i_group_done) begin
                twiddle_offset1 <= 0; 
    //        end else if (i_working && !i_fft_done) begin
            // Only increment if the data was valid
            end else if (i_data_valid) begin
                twiddle_offset1 <= twiddle_offset1 + (twiddle_idx_increment * 4);
            end else begin
                twiddle_offset1 <= twiddle_offset1; 
            end
        end
    end

endmodule