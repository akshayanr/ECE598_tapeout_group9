module butterfly_xbar_out(
    input [9:0] i_STRIDE,

    input [31:0] i_BUTTERFLY_1_TOP,
    input [31:0] i_BUTTERFLY_2_TOP, 
    input [31:0] i_BUTTERFLY_3_TOP, 
    input [31:0] i_BUTTERFLY_4_TOP,

    input [31:0] i_BUTTERFLY_1_BOTTOM, 
    input [31:0] i_BUTTERFLY_2_BOTTOM, 
    input [31:0] i_BUTTERFLY_3_BOTTOM, 
    input [31:0] i_BUTTERFLY_4_BOTTOM,

    output [127:0] o_READ_OUTPUT1, 
    output [127:0] o_READ_OUTPUT2

);

wire stride_greater_than_2; 
wire stride_equal_2;

assign stride_greater_than_2 = (i_STRIDE > 2);
assign stride_equal_2 = (i_STRIDE == 2);

assign o_READ_OUTPUT1[31:0]   = i_BUTTERFLY_1_TOP;
assign o_READ_OUTPUT1[63:32]  = (stride_greater_than_2 | stride_equal_2) ? i_BUTTERFLY_2_TOP : i_BUTTERFLY_1_BOTTOM;
assign o_READ_OUTPUT1[95:64]  = stride_greater_than_2 ? i_BUTTERFLY_3_TOP : (stride_equal_2 ? i_BUTTERFLY_1_BOTTOM : i_BUTTERFLY_2_TOP);
assign o_READ_OUTPUT1[127:96] = stride_greater_than_2 ? i_BUTTERFLY_4_TOP : i_BUTTERFLY_2_BOTTOM;

assign o_READ_OUTPUT2[31:0]   = stride_greater_than_2 ? i_BUTTERFLY_1_BOTTOM : i_BUTTERFLY_3_TOP;
assign o_READ_OUTPUT2[63:32]  = stride_greater_than_2 ? i_BUTTERFLY_2_BOTTOM : (stride_equal_2 ? i_BUTTERFLY_4_TOP : i_BUTTERFLY_3_BOTTOM);
assign o_READ_OUTPUT2[95:64]  = (stride_greater_than_2 | stride_equal_2) ? i_BUTTERFLY_3_BOTTOM : i_BUTTERFLY_4_TOP;
assign o_READ_OUTPUT2[127:96] = i_BUTTERFLY_4_BOTTOM;

endmodule