module point_config_tb();

    /////////////////////////////////////////
    // Set up signals
    parameter DELAY = 6;


    logic clk;
    logic resetn;

    logic [2:0] point_configuration;
    logic working;

    logic new_stage_trigger;
    logic [9:0] calcs_per_group;
    logic [7:0] stride_index_offset;
    logic [9:0] stride;
    logic [7:0] group_offset;

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
        .i_resetn(resetn),

        .i_point_configuration(point_configuration),
        .i_working(working),

        .o_new_stage_trigger(new_stage_trigger),
        .o_calcs_per_group(calcs_per_group),
        .o_stride_index_offset(stride_index_offset),
        .o_stride(stride),
        .o_group_offset(group_offset)
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
        $display("\n[MONITOR] Time | clock_count | point_configuration | resetn  | working | new_stage_trigger | calcs_per_group | stride_index_offset | stride | group_offset");
        $display("-----------------------------------------------------------------------");

        // $monitor runs in the background for the entire simulation
        $monitor("%8t |  %d | %b | %b | %b | %b | %d | %d | %d | %d", 
                 $time, 
                 clock_count,
                 point_configuration, 
                 resetn,
                 working, 
                 new_stage_trigger,
                 calcs_per_group, 
                 stride_index_offset, 
                 stride, 
                 group_offset);

        // Start
        clk = 0;
        resetn = 0;
        working = 0;
        clock_count = 0;
        point_configuration = 3'b000;
        #100;
        resetn = 1;
        working = 1;
        #100;
        resetn = 0;
        working = 0;
        clock_count = 0;
        point_configuration = 3'b111;
        #100;
        resetn = 1;
        working = 1;
        #12000;
        $finish;
    end

endmodule