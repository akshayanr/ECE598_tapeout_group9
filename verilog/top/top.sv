module top (
    input        clk, 
    input        rst_n, 

    input        scan_id,
    input        scan_phi,
    input        scan_phi_bar,
    input        scan_data_in,
    output logic scan_data_out,
    input        scan_load_chip,
    input        scan_load_chain
);

    logic [7:0] fft_raddress1; 
    logic [7:0] fft_raddress2; 
    logic [7:0] fft_waddress1; 
    logic [7:0] fft_waddress2; 

    // NOTE: use only port 1 for scan chain reads/writes

    logic [127:0] read_data1; 
    logic [127:0] read_data2; 
    logic [127:0] fft_wdata1; 
    logic [127:0] fft_wdata2; 


    logic scan_chain_wen;
    logic scan_chain_ren;
    logic [7:0] scan_chain_address;
    logic [127:0] scan_chain_wdata;
    logic [127:0] scan_chain_rdata;
    logic scan_chain_ready;

    // only need global signals for port 1
    logic [7:0] global_raddress1;
    logic [7:0] global_waddress1;
    logic [127:0] global_wdata1;

    logic sram_read_register;

    logic [127:0] scan_chain_bweb; 
    logic [127:0] bweb_mux; 

    logic core_wen;
    logic core_done;

    // =====================================
    // control registers
    // =====================================

    // point configuration control reg
    logic [2:0] pnt_cfg_rdata;
    logic        pnt_cfg_ready;
    logic pnt_cfg_ren;
    logic pnt_cfg_wen;
    logic [2:0] pnt_cfg_wdata;
    logic [2:0] point_config_reg;

   // start fft control reg
    logic start_fft_rdata;
    logic start_fft_ready;
    logic start_fft_ren;
    logic start_fft_wen;
    logic start_fft_wdata;
    logic start_fft_reg; 

    // reset fft control reg
    logic reset_fft_rdata;
    logic reset_fft_ready;
    logic reset_fft_ren;
    logic reset_fft_wen;
    logic reset_fft_wdata;
    logic reset_fft_reg;
    
    // cycle configuration control reg
    logic [10:0] cycle_cfg_rdata;
    logic        cycle_cfg_ready;
    logic cycle_cfg_ren;
    logic cycle_cfg_wen;
    logic [10:0] cycle_cfg_wdata;
    logic [10:0] cycle_counter_reg; 

    // done status reg
    logic fft_done_reg;


    // logic for write address and data to sram from either scan chain or core
    assign global_raddress1 = scan_chain_ren ? scan_chain_address : fft_raddress1;
    assign global_waddress1 = scan_chain_wen ? scan_chain_address : fft_waddress1;
    assign global_wdata1 = scan_chain_wen ? scan_chain_wdata : fft_wdata1;

    assign bweb_mux = scan_chain_wen ? scan_chain_bweb : 128'b0;

    fft_top fft(
        //General inputs
        .clk(clk), .rstn(reset_fft_reg), 

        .o_fft_done(core_done),

        //Connections from FFT to mem_interface
        .o_raddress1(fft_raddress1), .o_raddress2(fft_raddress2), 
        .o_waddress1(fft_waddress1), .o_waddress2(fft_waddress2), 

        .i_rdata1(read_data1), .i_rdata2(read_data2),
        .o_wdata1(fft_wdata1), .o_wdata2(fft_wdata2), 

        .o_global_write_enable(core_wen), 
        .o_sram_read_register(sram_read_register), 

        //Connections from FFT to control regs
        .i_working(start_fft_reg),
        .i_point_config(point_config_reg),
        .i_cycle_count(cycle_counter_reg)
    );

    mem_interface_sram mem_interface(

        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_raddress1(global_raddress1), //take in 7 bit address port 1
        .i_raddress2(fft_raddress2), //take in 7 bit address port 2
        .o_rdata1(read_data1), //this is the output rdata for port 1.
        .o_rdata2(read_data2), //this is the output rdata for port 2.
        .i_waddress1(global_waddress1), //this is the write address for port 1, mux between scan chain and core
        .i_waddress2(fft_waddress2), //this is the write address for port 2, mux between scan chain and core
        .i_wdata1(global_wdata1), //this is the wdata for port 1.
        .i_wdata2(fft_wdata2), //this is the wdata for port 2.
        .i_bweb1(bweb_mux), //this is the masking for port 1 -> comes from address decoder logic in mem_reg_mux.
        .i_bweb2(128'b0), //this is the masking for port 2 -> comes from address decoder logic in mem_reg_mux.
        .i_core_wen(core_wen), // active high.
        .i_core_ren(start_fft_reg), // active high.
        .i_sram_read_register(sram_read_register), // if 0, read from SRAM0 and write to SRAM1.
        .i_core_done(fft_done_reg), //this helps us determine which sram to read from
        .i_scan_chain_wen(scan_chain_wen), // active high, comes from scan chain when we want to write to sram
        .i_scan_chain_ren(scan_chain_ren),
        .o_scan_chain_sram_ready(scan_chain_ready)
        
    );

    scan_for_test scan_for_test_inst(
        // to the pads
        .clk_A(clk),           // input
        .rst_n(rst_n),           // input
        .scan_id(scan_id),         // input
        .scan_phi(scan_phi),        // input
        .scan_phi_bar(scan_phi_bar),    // input
        .scan_data_in(scan_data_in),    // input
        .scan_data_out(scan_data_out),   // output
        .scan_load_chip(scan_load_chip),  // input
        .scan_load_chain(scan_load_chain), // input

        // Group 1
        .sram_ren_A(scan_chain_ren), // output
        .sram_wen_A(scan_chain_wen), // output
        .sram_addr_A(scan_chain_address), // output
        .sram_bweb_A(scan_chain_bweb), // output
        .sram_wdata_A(scan_chain_wdata), // output
        .sram_rdata_A(read_data1), // input
        .sram_ready_A(scan_chain_ready), // input


        // point configuration control reg
        .pnt_cfg_ren(pnt_cfg_ren),   // output
        .pnt_cfg_wen(pnt_cfg_wen),   // output
        .pnt_cfg_wdata(pnt_cfg_wdata), // output
        .pnt_cfg_rdata(pnt_cfg_rdata), // input
        .pnt_cfg_ready(pnt_cfg_ready), // input

        // cycle configuration control reg
        .cycle_cfg_ren(cycle_cfg_ren),   // output
        .cycle_cfg_wen(cycle_cfg_wen),   // output
        .cycle_cfg_wdata(cycle_cfg_wdata), // output
        .cycle_cfg_rdata(cycle_cfg_rdata), // input
        .cycle_cfg_ready(cycle_cfg_ready), // input

        // start fft control reg
        .start_fft_ren(start_fft_ren),   // output
        .start_fft_wen(start_fft_wen),   // output
        .start_fft_wdata(start_fft_wdata), // output
        .start_fft_rdata(start_fft_rdata), // input
        .start_fft_ready(start_fft_ready), // input

        // reset fft control reg
        .reset_fft_ren(reset_fft_ren),   // output
        .reset_fft_wen(reset_fft_wen),   // output
        .reset_fft_wdata(reset_fft_wdata), // output
        .reset_fft_rdata(reset_fft_rdata), // input
        .reset_fft_ready(reset_fft_ready), // input

        // done status reg
        .fft_done(fft_done_reg) // input
    );

    start_fft_reg start_fft (
        .start_fft_wdata(start_fft_wdata), // input
        .clk(clk),                         // input
        .rst_n(rst_n && reset_fft_reg),    // input
        .start_fft_wen(start_fft_wen),     // input
        .start_fft_ren(start_fft_ren),     // input
        .start_fft_reg(start_fft_reg),     // output
        .start_fft_rdata(start_fft_rdata), // output
        .start_fft_ready(start_fft_ready)  // output
    );

    reset_fft_reg reset_fft (
        .reset_fft_wdata(reset_fft_wdata), // input
        .clk(clk),                         // input
        .rst_n(rst_n),                     // input
        .reset_fft_wen(reset_fft_wen),     // input
        .reset_fft_ren(reset_fft_ren),     // input
        .reset_fft_reg(reset_fft_reg),     // output
        .reset_fft_rdata(reset_fft_rdata), // output
        .reset_fft_ready(reset_fft_ready)  // output
    );
   
    pnt_cfg_reg pnt_cfg (
        .pnt_cfg_wdata(pnt_cfg_wdata), // input
        .clk(clk),                     // input
        .rst_n(rst_n),                 // input
        .pnt_cfg_wen(pnt_cfg_wen),     // input
        .pnt_cfg_ren(pnt_cfg_ren),     // input
        .pnt_cfg_reg(point_config_reg),     // output
        .pnt_cfg_rdata(pnt_cfg_rdata), // output
        .pnt_cfg_ready(pnt_cfg_ready)  // output
    );

    cycle_cfg_reg cycle_cfg (
        .cycle_cfg_wdata(cycle_cfg_wdata), // input
        .clk(clk),                         // input
        .rst_n(rst_n),                     // input
        .cycle_cfg_wen(cycle_cfg_wen),     // input
        .cycle_cfg_ren(cycle_cfg_ren),     // input
        .cycle_cfg_reg(cycle_counter_reg), // output
        .cycle_cfg_rdata(cycle_cfg_rdata), // output
        .cycle_cfg_ready(cycle_cfg_ready)  // output
    );

    fft_done_reg fft_done_status (
        .clk(clk),                      // input
        .rst_n(rst_n && reset_fft_reg), // input
        .core_done(core_done),          // input
        .fft_done_reg(fft_done_reg)     // output
    );



endmodule