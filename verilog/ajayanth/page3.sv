module page3(
    input [9:0] STRIDE,
    input [127:0] READ_OUTPUT1, 
    input [127:0] READ_OUTPUT2,

    output [31:0] BUTTERFLY_1_BOTTOM, 
    output [31:0] BUTTERFLY_2_BOTTOM, 
    output [31:0] BUTTERFLY_3_BOTTOM, 

    output [31:0] BUTTERFLY_2_TOP, 
    output [31:0] BUTTERFLY_3_TOP, 
    output [31:0] BUTTERFLY_4_TOP
);

wire stride_greater_than_2; 
wire stride_equal_2;

assign stride_greater_than_2 = (STRIDE > 2);
assign stride_equal_2 = (STRIDE == 2);

assign BUTTERFLY_1_BOTTOM = stride_greater_than_2 ? (READ_OUTPUT2[31:0]) : (stride_equal_2 ? READ_OUTPUT1[95:64] : READ_OUTPUT1[63:32]);
assign BUTTERFLY_2_BOTTOM = stride_greater_than_2 ? (READ_OUTPUT2[63:32]) : (READ_OUTPUT1[127:96]);
assign BUTTERFLY_3_BOTTOM = stride_greater_than_2 ? (READ_OUTPUT2[95:64]) : (stride_equal_2 ? READ_OUTPUT2[95:64] : READ_OUTPUT2[63:32]);
assign BUTTERFLY_2_TOP = (stride_greater_than_2 | stride_equal_2) ? (READ_OUTPUT1[63:32]) : (READ_OUTPUT1[95:64]);
assign BUTTERFLY_3_TOP = (stride_greater_than_2) ? (READ_OUTPUT1[95:64]) : (READ_OUTPUT2[31:0]);
assign BUTTERFLY_4_TOP = stride_greater_than_2 ? (READ_OUTPUT1[127:96]) : (stride_equal_2 ? READ_OUTPUT2[63:32] : READ_OUTPUT[95:64]);


endmodule