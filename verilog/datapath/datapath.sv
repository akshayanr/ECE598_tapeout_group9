module datapath #(
    parameter BUTTERFLY_DELAY = 2,
    parameter MULT_DELAY = 3
)(
    input clk,
    input [127:0]   i_data1,
    input [127:0]   i_data2,
    input [7:0]     i_addr1,
    input [7:0]     i_addr2,
    input           i_valid,

    input [9:0] i_stride,

    input [8:0] i_twiddle_offset1,
    input [8:0] i_twiddle_offset2,
    input [8:0] i_twiddle_offset3,
    input [8:0] i_twiddle_offset4,

    output [127:0] o_data1,
    output [127:0] o_data2,
    output [7:0]   o_addr1,
    output [7:0]   o_addr2,
    output         o_valid
);

parameter ADDRESS_DELAY = BUTTERFLY_DELAY + MULT_DELAY;

logic [31:0] butterfly_1_top_in;
logic [31:0] butterfly_2_top_in;
logic [31:0] butterfly_3_top_in;
logic [31:0] butterfly_4_top_in;

logic [31:0] butterfly_1_bot_in;
logic [31:0] butterfly_2_bot_in;
logic [31:0] butterfly_3_bot_in;
logic [31:0] butterfly_4_bot_in;

logic [31:0] butterfly_1_top_out;
logic [31:0] butterfly_2_top_out;
logic [31:0] butterfly_3_top_out;
logic [31:0] butterfly_4_top_out;

logic [31:0] butterfly_1_bot_out;
logic [31:0] butterfly_2_bot_out;
logic [31:0] butterfly_3_bot_out;
logic [31:0] butterfly_4_bot_out;

logic [7:0] address1_delay [ADDRESS_DELAY-1:0];
logic [7:0] address2_delay [ADDRESS_DELAY-1:0];
logic [ADDRESS_DELAY-1:0] valid_delay;
logic [9:0] stride_delay [ADDRESS_DELAY-1:0];

assign o_addr1 = address1_delay[ADDRESS_DELAY-1];
assign o_addr2 = address2_delay[ADDRESS_DELAY-1];
assign o_valid = valid_delay[ADDRESS_DELAY-1];

logic [127:0] data1_in;
logic [127:0] data2_in;
logic [7:0] addr1_in;
logic [7:0] addr2_in;

// If the data isn't valid, don't pass junk through the pipeline
assign data1_in = i_valid ? i_data1 : 128'd0;
assign data2_in = i_valid ? i_data2 : 128'd0;
assign addr1_in = i_valid ? i_addr1 : 8'd0;
assign addr2_in = i_valid ? i_addr2 : 8'd0;

butterfly_xbar_in xbar_in (
    .i_STRIDE(i_stride),
    .i_READ_OUTPUT1(data1_in), 
    .i_READ_OUTPUT2(data2_in),

    .o_BUTTERFLY_1_TOP(butterfly_1_top_in), 
    .o_BUTTERFLY_2_TOP(butterfly_2_top_in), 
    .o_BUTTERFLY_3_TOP(butterfly_3_top_in), 
    .o_BUTTERFLY_4_TOP(butterfly_4_top_in),

    .o_BUTTERFLY_1_BOTTOM(butterfly_1_bot_in), 
    .o_BUTTERFLY_2_BOTTOM(butterfly_2_bot_in), 
    .o_BUTTERFLY_3_BOTTOM(butterfly_3_bot_in),
    .o_BUTTERFLY_4_BOTTOM(butterfly_4_bot_in)
);

butterfly_xbar_out xbar_out (
    .i_STRIDE(stride_delay[ADDRESS_DELAY-1]),

    .i_BUTTERFLY_1_TOP(butterfly_1_top_out), 
    .i_BUTTERFLY_2_TOP(butterfly_2_top_out), 
    .i_BUTTERFLY_3_TOP(butterfly_3_top_out), 
    .i_BUTTERFLY_4_TOP(butterfly_4_top_out),

    .i_BUTTERFLY_1_BOTTOM(butterfly_1_bot_out), 
    .i_BUTTERFLY_2_BOTTOM(butterfly_2_bot_out), 
    .i_BUTTERFLY_3_BOTTOM(butterfly_3_bot_out),
    .i_BUTTERFLY_4_BOTTOM(butterfly_4_bot_out),

    .o_READ_OUTPUT1(o_data1), 
    .o_READ_OUTPUT2(o_data2)
);

full_butterfly butterfly1 (
    .clk(clk),
    .i_butterfly_top(butterfly_1_top_in),
    .i_butterfly_bot(butterfly_1_bot_in),
    .i_twiddle_addr(i_twiddle_offset1),
    .i_valid(i_valid),

    .o_butterfly_top(butterfly_1_top_out),
    .o_butterfly_bot(butterfly_1_bot_out)
);

full_butterfly butterfly2 (
    .clk(clk),
    .i_butterfly_top(butterfly_2_top_in),
    .i_butterfly_bot(butterfly_2_bot_in),
    .i_twiddle_addr(i_twiddle_offset2),
    .i_valid(i_valid),

    .o_butterfly_top(butterfly_2_top_out),
    .o_butterfly_bot(butterfly_2_bot_out)
);

full_butterfly butterfly3 (
    .clk(clk),
    .i_butterfly_top(butterfly_3_top_in),
    .i_butterfly_bot(butterfly_3_bot_in),
    .i_twiddle_addr(i_twiddle_offset3),
    .i_valid(i_valid),

    .o_butterfly_top(butterfly_3_top_out),
    .o_butterfly_bot(butterfly_3_bot_out)
);

full_butterfly butterfly4 (
    .clk(clk),
    .i_butterfly_top(butterfly_4_top_in),
    .i_butterfly_bot(butterfly_4_bot_in),
    .i_twiddle_addr(i_twiddle_offset4),
    .i_valid(i_valid),

    .o_butterfly_top(butterfly_4_top_out),
    .o_butterfly_bot(butterfly_4_bot_out)
);

integer i;
always_ff @(posedge clk) begin
    for(i = 1; i < ADDRESS_DELAY; i = i + 1) begin
        address1_delay[i] <= address1_delay[i-1];
        address2_delay[i] <= address2_delay[i-1];
        valid_delay[i]    <= valid_delay[i-1];
        stride_delay[i]   <= stride_delay[i-1];
    end

    address1_delay[0] <= addr1_in;
    address2_delay[0] <= addr2_in;
    valid_delay[0]    <= i_valid;
    stride_delay[0]   <= i_stride;
end

endmodule