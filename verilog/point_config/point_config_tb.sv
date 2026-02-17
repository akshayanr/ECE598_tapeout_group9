module point_config_tb();

    /////////////////////////////////////////
    // Set up signals
    parameter DELAY = 6;


    logic clk;
    logic rstn;

    logic [2:0] i_point_config;
    logic i_working;

    logic o_new_stage_trigger;
    logic o_sram_read_register;
    logic o_valid_data;
    logic o_fft_done;
    logic [9:0] o_calcs_per_group;
    logic [7:0] o_stride_index_offset; 
    logic [9:0] o_stride; 
    logic [7:0] o_group_offset; 
    
    /////////////////////////////////////////
    // SDF annotation
    `ifdef SYN
        initial $sdf_annotate("../../syn/pages/point_config.syn.sdf", point_config_tb.dut);
    `endif

    /////////////////////////////////////////
    // Set up DUT

    point_config 
    #( .DELAY(DELAY)
    ) dut (
        .clk(clk),
        .i_resetn(rstn),
        .i_point_configuration(i_point_config),
        .i_working(i_working),

        .o_new_stage_trigger(o_new_stage_trigger),
        .o_sram_read_register(o_sram_read_register),
        .o_valid_data(o_valid_data),
        .o_fft_done(o_fft_done),
        .o_calcs_per_group(o_calcs_per_group),
        .o_stride_index_offset(o_stride_index_offset),
        .o_stride(o_stride),
        .o_group_offset(o_group_offset)
    );

    /////////////////////////////////////////
    // Run Simulation

    integer clock_count;
    always begin
        #`CLK_PERIOD_HALF clk = ~clk;
    end
    always @(posedge clk) begin
        clock_count = clock_count + 1;
    end

    initial begin
        $display("\n[MONITOR] Time | clk_cnt | rstn | i_point_config | i_working | o_new_stage_trigger | o_sram_read_register | o_valid_data | o_calcs_per_group | o_stride_index_offset | o_stride | o_group_offset");
        $display("-----------------------------------------------------------------------");

        // $monitor runs in the background for the entire simulation
        $monitor("%8t              |  %d  |  %b   | %b  |  %b  |  %b  |  %b  |  %b  | %d  | %d  |  %d  |  %d  |  %b", 
                 $time, 
                 clock_count,
                 rstn,
                 i_point_config, 
                 i_working,
                 o_new_stage_trigger, 
                 o_sram_read_register,
                 o_valid_data, 
                 o_calcs_per_group, 
                 o_stride_index_offset, 
                 o_stride,
                 o_group_offset,
                 o_fft_done);

        // Start
        clk = 0;
        rstn = 0;
        i_working = 0;
        clock_count = 0;
        i_point_config = 3'b000;
        #100;
        rstn = 1;
        i_working = 1;
        #1000;
        rstn = 0;
        i_working = 0;
        clock_count = 0;
        i_point_config = 3'b010;
        #100;
        rstn = 1;
        i_working = 1;
        #1000;
        $finish;
    end

endmodule