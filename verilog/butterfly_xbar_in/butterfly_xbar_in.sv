module butterfly_xbar_in(
    input [9:0] i_STRIDE,
    input [127:0] i_READ_OUTPUT1, 
    input [127:0] i_READ_OUTPUT2,

    output [31:0] o_BUTTERFLY_1_TOP,
    output [31:0] o_BUTTERFLY_2_TOP, 
    output [31:0] o_BUTTERFLY_3_TOP, 
    output [31:0] o_BUTTERFLY_4_TOP,

    output [31:0] o_BUTTERFLY_1_BOTTOM, 
    output [31:0] o_BUTTERFLY_2_BOTTOM, 
    output [31:0] o_BUTTERFLY_3_BOTTOM, 
    output [31:0] o_BUTTERFLY_4_BOTTOM

);

wire stride_greater_than_2; 
wire stride_equal_2;

assign stride_greater_than_2 = (i_STRIDE > 2);
assign stride_equal_2 = (i_STRIDE == 2);

assign o_BUTTERFLY_1_TOP = i_READ_OUTPUT1[31:0];
assign o_BUTTERFLY_2_TOP = (stride_greater_than_2 | stride_equal_2) ? (i_READ_OUTPUT1[63:32]) : (i_READ_OUTPUT1[95:64]);
assign o_BUTTERFLY_3_TOP = (stride_greater_than_2) ? (i_READ_OUTPUT1[95:64]) : (i_READ_OUTPUT2[31:0]);
assign o_BUTTERFLY_4_TOP = stride_greater_than_2 ? (i_READ_OUTPUT1[127:96]) : (stride_equal_2 ? i_READ_OUTPUT2[63:32] : i_READ_OUTPUT2[95:64]);

assign o_BUTTERFLY_1_BOTTOM = stride_greater_than_2 ? (i_READ_OUTPUT2[31:0]) : (stride_equal_2 ? i_READ_OUTPUT1[95:64] : i_READ_OUTPUT1[63:32]);
assign o_BUTTERFLY_2_BOTTOM = stride_greater_than_2 ? (i_READ_OUTPUT2[63:32]) : (i_READ_OUTPUT1[127:96]);
assign o_BUTTERFLY_3_BOTTOM = stride_greater_than_2 ? (i_READ_OUTPUT2[95:64]) : (stride_equal_2 ? i_READ_OUTPUT2[95:64] : i_READ_OUTPUT2[63:32]);
assign o_BUTTERFLY_4_BOTTOM = i_READ_OUTPUT2[127:96];



endmodule