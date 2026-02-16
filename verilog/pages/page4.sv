module page4(
    input i_group_done, 
    input [2:0] i_point_configuration, 
    input [9:0] i_reset, 
    input [10:0] i_stride, //Idk if this is the right width
    input i_new_stage_trigger,
    input clock
    
    output [9:0] o_butterfly2_twiddle_offset, 
    output [9:0] o_butterfly3_twiddle_offset, 
    output [9:0] o_butterfly4_twiddl_offset //idk if these are the right width either, easy to swap
);

    logic [9:0] twiddle_offset1; 

    wire [9:0] twiddle_offset1_comb;
    wire [9:0] twiddle_offset2; 
    wire [9:0] twiddle_offset3; 
    wire [9:0] twiddle_offset4; 
    wire [8:0] reset_input; 

    wire [7:0] twiddle_index_increment
    

    wire stride_greater_than_2; 
    wire stride_equal_2;

    assign stride_greater_than_2 = (i_stride > 2);
    assign stride_equal_2 = (i_stride == 2);

    assign twiddle_offset1_comb;


    assign reset_input = (8'b10000000 >> i_point_configuration);

    assign twiddle_index_increment = i_new_stage_trigger ? i_reset : i_reset_input; 
    

    assign twiddle_offset2 = twiddle_offset1_comb + twiddle_index_increment;
    assign twiddle_offset3 = twiddle_offset1_comb + (twiddle_index_increment << 1);
    assign twiddle_offset4 = twiddle_offset1_comb + (twiddle_index_increment << 2);

    assign o_butterfly2_twiddle_offset = (stride_greater_than_2 || stride_equal_2) ? twiddle_offset2 : twiddle_offset1;
    assign o_butterfly3_twiddle_offset = stride_greater_than2 ? twiddle_offset3 : twiddle_offset1; 
    assign o_butterfly4_twiddle_offset = stride_greater_than2 ? twiddle_offset4 : (stride_equal_2 ? twiddle_offset2 : twiddle_offset1);

    always @(posedge clock) begin 

        if(group_done) twiddle_offset1 <= 0; 
        else twiddle_offset1 = twiddle_offset1_comb + (twiddle_index_increment << 2);
    end

endmodule