module scan_for_test( 
    // input signals
    input clk_A,
    input rst_n,

    // To the pads
    input scan_id,
    input scan_phi,
    input scan_phi_bar,
    input scan_data_in,
    output reg scan_data_out,
    input scan_load_chip,
    input scan_load_chain,

    // Group 1
    output reg sram_ren_A,
    output reg sram_wen_A,
    //output reg [8:0] sram_addr_A,
    output reg [7:0] sram_addr_A,
    output reg [127:0] sram_bweb_A,
    //output reg [31:0] sram_wdata_A,
    output reg [127:0] sram_wdata_A,
    //input [31:0] sram_rdata_A,
    input [127:0] sram_rdata_A,
    input sram_ready_A,


    // point configuration control reg
    output reg pnt_cfg_ren,
    output reg pnt_cfg_wen,
    output reg [2:0] pnt_cfg_wdata,
    input [2:0] pnt_cfg_rdata,
    input pnt_cfg_ready,

    // cycle configuration control reg
    output reg cycle_cfg_ren,
    output reg cycle_cfg_wen,
    output reg [10:0] cycle_cfg_wdata,
    input [10:0] cycle_cfg_rdata,
    input cycle_cfg_ready,

    // start fft control reg
    output reg start_fft_ren,
    output reg start_fft_wen,
    output reg start_fft_wdata,
    input start_fft_rdata,
    input start_fft_ready,

    // reset fft control reg
    output reg reset_fft_ren,
    output reg reset_fft_wen,
    output reg reset_fft_wdata,
    input reset_fft_rdata,
    input reset_fft_ready,

    // done status reg
    input fft_done,

    // which SRAM to read from
    input select_sram_reg
    
);
    // block_scan
    reg static_wen;
    reg static_ren;
    reg [19:0]  static_addr;
    reg [32-1:0]  static_wdata;
    reg [31:0]  static_rdata;
    reg static_ready;

    reg  scan_id_A;
    reg  static_wen_A;
    reg  static_ren_A;
    reg  [19:0] static_addr_A;
    reg  [31:0] static_wdata_A;
    reg  [31:0] static_rdata_A;
    reg  static_ready_A;

    block_scan block_scan_inst (
        // Inputs & outputs to the group mux
        .static_wen(static_wen),
        .static_ren(static_ren),
        .static_addr(static_addr),
        .static_wdata(static_wdata),
        .static_rdata(static_rdata),
        .static_ready(static_ready),

        // To the pads
        .scan_phi(scan_phi),
        .scan_phi_bar(scan_phi_bar),
        .scan_data_in(scan_data_in),
        .scan_data_out(scan_data_out),
        .scan_load_chip(scan_load_chip),
        .scan_load_chain(scan_load_chain)
    );

    group_mux group_mux_inst(
         // Inputs & outputs to the pads
         .scan_id(scan_id),

         // To the group mux
        .static_wen(static_wen),
        .static_ren(static_ren),
        .static_addr(static_addr),
        .static_wdata(static_wdata),
        .static_rdata(static_rdata),
        .static_ready(static_ready),

         // To group A
        .static_wen_A(static_wen_A),
        .static_ren_A(static_ren_A),
        .static_addr_A(static_addr_A),
        .static_wdata_A(static_wdata_A),
        .static_rdata_A(static_rdata_A),
        .static_ready_A(static_ready_A),
        .scan_id_A(scan_id_A)
    );

    // group A
    group_scan_mem_reg_if group_scan_mem_reg_if_A(
        // Inputs & outputs to the group_mux
        .clk(clk_A),                   
        .rst_n(rst_n),               
        .static_wen_group_mux   (static_wen_A),
        .static_ren_group_mux   (static_ren_A),
        .static_addr_group_mux  (static_addr_A),
        .static_wdata_group_mux (static_wdata_A),
        .static_rdata_group_mux (static_rdata_A),
        .static_ready_group_mux (static_ready_A),
        .scan_id_group_mux      (scan_id_A),

        // To SRAM
        .sram_ren   (sram_ren_A),
        .sram_wen   (sram_wen_A),
        .sram_addr  (sram_addr_A),
        .sram_bweb  (sram_bweb_A),
        .sram_wdata (sram_wdata_A),
        .sram_rdata (sram_rdata_A),
        .sram_ready (sram_ready_A),

        // point configuration control reg
        .pnt_cfg_ren(pnt_cfg_ren),
        .pnt_cfg_wen(pnt_cfg_wen),
        .pnt_cfg_wdata(pnt_cfg_wdata),
        .pnt_cfg_rdata(pnt_cfg_rdata),
        .pnt_cfg_ready(pnt_cfg_ready),

        //cycle configuration control reg.
        .cycle_cfg_ren(cycle_cfg_ren),
        .cycle_cfg_wen(cycle_cfg_wen),
        .cycle_cfg_wdata(cycle_cfg_wdata),
        .cycle_cfg_rdata(cycle_cfg_rdata),
        .cycle_cfg_ready(cycle_cfg_ready),

        // start fft control reg
        .start_fft_ren(start_fft_ren),
        .start_fft_wen(start_fft_wen),
        .start_fft_wdata(start_fft_wdata),
        .start_fft_rdata(start_fft_rdata),
        .start_fft_ready(start_fft_ready),

        // reset fft control reg
        .reset_fft_ren(reset_fft_ren),
        .reset_fft_wen(reset_fft_wen),
        .reset_fft_wdata(reset_fft_wdata),
        .reset_fft_rdata(reset_fft_rdata),
        .reset_fft_ready(reset_fft_ready),

        // done status reg
        .fft_done(fft_done)

        // which SRAM to read from
        //.select_sram_reg(select_sram_reg)
    );

endmodule 