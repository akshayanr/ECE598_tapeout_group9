module fft_top(
    input clk,
    input rstn,
    input        i_working,
    input [2:0]  i_point_config,
    input [10:0] i_cycle_count,
    output       o_fft_done,
    
    output  [7:0]   o_raddress1,
    output  [7:0]   o_raddress2,
    input   [127:0] i_rdata1,
    input   [127:0] i_rdata2,
    output  [7:0]   o_waddress1,
    output  [7:0]   o_waddress2,
    output  [127:0] o_wdata1,
    output  [127:0] o_wdata2,
    output          o_global_write_enable,
    output          o_sram_read_register
);

    // Datapath IN
    logic [127:0]   rd_data1;
    logic [127:0]   rd_data2;
    logic [7:0]     rd_addr1;
    logic [7:0]     rd_addr2;

    // Datapath OUT
    logic [127:0]   wr_data1;
    logic [127:0]   wr_data2;
    logic [7:0]     wr_addr1;
    logic [7:0]     wr_addr2;
    logic           valid_data_out;
    logic           fft_done;

    assign o_raddress1 = rd_addr1;
    assign o_raddress2 = rd_addr2;
    assign rd_data1    = i_rdata1;
    assign rd_data2    = i_rdata2;
    assign o_waddress1 = wr_addr1;
    assign o_waddress2 = wr_addr2;
    assign o_wdata1    = wr_data1;
    assign o_wdata2    = wr_data2;
    assign o_global_write_enable = valid_data_out;
    assign o_fft_done  = fft_done;

    // Outputs for point config
    logic       new_stage_trigger;
    logic [9:0] calcs_per_group;
    logic [7:0] stride_index_offset;
    logic [9:0] stride;
    logic [7:0] group_offset;
    logic       valid_data_in;


    point_config points(
        .clk(clk),
        .i_resetn(rstn),
        .i_point_configuration(i_point_config),
        .i_working(i_working),
        .i_cycle_count(i_cycle_count),

        .o_new_stage_trigger(new_stage_trigger),
        .o_sram_read_register(o_sram_read_register),
        .o_valid_data(valid_data_in),
        .o_fft_done(fft_done),
        .o_calcs_per_group(calcs_per_group),
        .o_stride_index_offset(stride_index_offset),
        .o_stride(stride),
        .o_group_offset(group_offset)
    );

    // Outputs for address gen
    logic       group_done;

    address_gen address(
        .clk(clk),
        .i_resetn(rstn),
        .i_working(i_working),
        .i_calcs_per_group(calcs_per_group),
        .i_stride_idx_offset(stride_index_offset),
        .i_group_offset(group_offset),
        .i_new_stage_trigger(new_stage_trigger),
        .i_fft_done(fft_done),

        .o_group_done(group_done),
        .o_address_1(rd_addr1),
        .o_address_2(rd_addr2)
    );

    logic [8:0] butterfly1_twiddle;
    logic [8:0] butterfly2_twiddle; 
    logic [8:0] butterfly3_twiddle; 
    logic [8:0] butterfly4_twiddle;

    twiddle_gen twiddler(
        .clk(clk),
        .i_resetn(rstn),
        .i_point_configuration(i_point_config),
        .i_stride(stride),
//        .i_working(i_working),
        .i_group_done(group_done),
        .i_new_stage_trigger(new_stage_trigger),
//        .i_fft_done(fft_done),
        .i_data_valid(valid_data_in),

        .o_butterfly1_twiddle(butterfly1_twiddle),
        .o_butterfly2_twiddle(butterfly2_twiddle),
        .o_butterfly3_twiddle(butterfly3_twiddle),
        .o_butterfly4_twiddle(butterfly4_twiddle)
    );

    logic [7:0] rd_addr1_delayed;
    logic [7:0] rd_addr2_delayed;
    always @(posedge clk) begin
        rd_addr1_delayed <= rd_addr1;
        rd_addr2_delayed <= rd_addr2;
    end

    datapath data(
        .clk(clk),
        .i_data1(rd_data1),
        .i_data2(rd_data2),
        .i_addr1(rd_addr1_delayed),
        .i_addr2(rd_addr2_delayed),
        .i_valid(valid_data_in),
        .i_stride(stride),
        .i_twiddle_offset1(butterfly1_twiddle),
        .i_twiddle_offset2(butterfly2_twiddle),
        .i_twiddle_offset3(butterfly3_twiddle),
        .i_twiddle_offset4(butterfly4_twiddle),

        .o_data1(wr_data1),
        .o_data2(wr_data2),
        .o_addr1(wr_addr1),
        .o_addr2(wr_addr2),
        .o_valid(valid_data_out)
    );

endmodule