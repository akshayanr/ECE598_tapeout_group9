module address_gen_tb();

    /////////////////////////////////////////
    // Set up signals

    logic clk;
    logic resetn;

    logic working;
    logic [9:0] calcs_per_group;
    logic [7:0] stride_idx_offset;
    logic [7:0] group_offset;
    logic new_stage_trigger;

    logic group_done;
    logic [7:0] address1;
    logic [7:0] address2;

    /////////////////////////////////////////
    // SDF annotation
    `ifdef SYN
        initial $sdf_annotate("../../syn/pages/address_gen.syn.sdf", address_gen_tb.dut);
    `endif

    /////////////////////////////////////////
    // Set up DUT

    address_gen dut (
        .clk(clk),
        .i_resetn(resetn),

        .i_working(working),
        .i_calcs_per_group(calcs_per_group),
        .i_stride_idx_offset(stride_idx_offset),
        .i_group_offset(group_offset),
        .i_new_stage_trigger(new_stage_trigger),

        .o_group_done(group_done),
        .o_address_1(address1),
        .o_address_2(address2)
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
        $display("\n[MONITOR] Time | clock_count | resetn | working | new_stage_trigger | calcs_per_group | stride_index_offset | group_offset | group_done | address1 | address2");
        $display("-----------------------------------------------------------------------");

        // $monitor runs in the background for the entire simulation
        $monitor("%8t | %d | %b | %b | %b | %d  | %d | %d | %b | %d | %d", 
                 $time, 
                 clock_count,
                 resetn,
                 working, 
                 new_stage_trigger,
                 calcs_per_group, 
                 stride_idx_offset, 
                 group_offset,
                 group_done,
                 address1,
                 address2
                 );

        // Start
        clk = 0;
        clock_count = 0;
        resetn = 0;
        working = 0;
        new_stage_trigger = 0;
        calcs_per_group = 512;
        stride_idx_offset = 128;
        group_offset    = 15;
        #100;
        resetn = 1;
        working = 1;
        #1000;
        $finish;
    end

endmodule