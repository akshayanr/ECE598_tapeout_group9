module twiddle_gen_tb();

    /////////////////////////////////////////
    // Set up signals

    logic clk;
    logic resetn;
    logic group_done; 
    logic new_stage_trigger;
    logic [2:0] point_configuration;
    logic [9:0] stride;

    logic [8:0] butterfly1_twiddle;
    logic [8:0] butterfly2_twiddle;
    logic [8:0] butterfly3_twiddle;
    logic [8:0] butterfly4_twiddle;

   /////////////////////////////////////////
    // SDF annotation
    `ifdef SYN
        initial $sdf_annotate("../../syn/twiddle_gen/twiddle_gen.syn.sdf", twiddle_gen_tb.dut);
    `endif

    /////////////////////////////////////////
    // Set up DUT

    twiddle_gen dut(
        .clk(clk),
        .i_resetn(resetn),

        .i_point_configuration(point_configuration),
        .i_stride(stride),
        .i_group_done(group_done),
        .i_new_stage_trigger(new_stage_trigger),

        .o_butterfly1_twiddle(butterfly1_twiddle),
        .o_butterfly2_twiddle(butterfly2_twiddle),
        .o_butterfly3_twiddle(butterfly3_twiddle),
        .o_butterfly4_twiddle(butterfly4_twiddle)
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
        $display("\n[MONITOR] Time | clock_count | resetn | point_configuration  | stride | group_done | new_stage_trigger | butterfly1_twiddle | butterfly2_twiddle | butterfly3_twiddle | butterfly4_twiddle");
        $display("-----------------------------------------------------------------------");

        // $monitor runs in the background for the entire simulation
        $monitor("%8t |  %d | %b | %b  | %d | %b | %b | %d | %d | %d | %d", 
                 $time, 
                 clock_count,
                 resetn,
                 point_configuration, 
                 stride, 
                 group_done, 
                 new_stage_trigger, 
                 butterfly1_twiddle, 
                 butterfly2_twiddle,
                 butterfly3_twiddle,
                 butterfly4_twiddle);

        // Start
        clk = 0;
        resetn = 0;
        clock_count = 0;
        point_configuration = 3'b001;
        group_done = 0;
        new_stage_trigger = 0;
        stride = 8;
        #100;
        resetn = 1;
        #100;
        @(posedge clk);
        #1 group_done = 1;
        @(posedge clk);
        #1 group_done = 0;
        #100;
        #1;
        resetn = 0;
        group_done = 0;
        #100;
        resetn = 1;
        #100;
        @(posedge clk)
        #1 
        new_stage_trigger = 1;
        group_done = 1;
        @(posedge clk);
        #1 
        new_stage_trigger = 0;
        group_done = 0;
        #100;
        $finish;
    end

endmodule