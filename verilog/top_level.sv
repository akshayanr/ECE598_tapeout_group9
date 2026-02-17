module top_level(
    logic clk;
    logic rstn;

);

    // Inputs for point config
    logic       working;
    logic [2:0] point_configuration;

    // Outputs for point config
    logic       new_stage_trigger;
    logic [9:0] calcs_per_group;
    logic [7:0] stride_index_offset;
    logic [9:0] stride;
    logic [7:0] group_offset;

    point_config points(
        .clk(clk),
        .i_resetn(rstn),
        .i_point_configuration(point_configuration),
        .i_working(working),

        .o_calcs_per_group(calcs_per_group),
        .o_stride_index_offset(stride_index_offset),
        .o_stride(stride),
        .o_group_offset(group_offset)
    );

    // Outputs for address gen
    logic       group_done;
    logic [7:0] address_1;
    logic [7:0] address_2;

    address_gen address(
        .clk(clk),
        .i_resetn(rstn),
        .i_working(working),
        .i_calcs_per_group(calcs_per_group),
        .i_stride_idx_offset(stride_index_offset),
        .i_group_offset(group_offset),
        .i_new_stage_trigger(new_stage_trigger),

        .o_group_done(group_done),
        .o_address_1(address_1),
        .o_address_2(address_2)
    );

    logic [8:0] butterfly1_twiddle;
    logic [8:0] butterfly2_twiddle; 
    logic [8:0] butterfly3_twiddle; 
    logic [8:0] butterfly4_twiddle;

    twiddle_gen twiddler(
        .clk(clk),
        .i_resetn(rstn),
        .i_point_configuration(point_configuration),
        .i_stride(stride),
        .i_group_done(group_done),
        .i_new_stage_trigger(new_stage_trigger),

        .o_butterfly1_twiddle(butterfly1_twiddle),
        .o_butterfly2_twiddle(butterfly2_twiddle),
        .o_butterfly3_twiddle(butterfly3_twiddle),
        .o_butterfly4_twiddle(butterfly4_twiddle)
    );

    // Input (Change when adding scan chain)
    logic [127:0]   i_data1;
    logic [127:0]   i_data2;
    logic           i_valid;

    // Outputs
    logic [127:0]   o_data1;
    logic [127:0]   o_data2;
    logic [7:0]     o_addr1;
    logic [7:0]     o_addr2;
    logic           o_valid;

    datapath data(
        .clk(clk),
        .i_data1(i_data1),
        .i_data2(i_data2),
        .i_addr1(address_1),
        .i_addr2(address_2),
        .i_valid(i_valid),
        .i_stride(stride),
        .twiddle_offset1(butterfly1_twiddle),
        .twiddle_offset2(butterfly2_twiddle),
        .twiddle_offset3(butterfly3_twiddle),
        .twiddle_offset4(butterfly4_twiddle),

        .o_data1(o_data1),
        .o_data2(o_data2),
        .o_addr1(o_addr1),
        .o_addr2(o_addr2),
        .o_valid(o_valid)
    );

endmodule