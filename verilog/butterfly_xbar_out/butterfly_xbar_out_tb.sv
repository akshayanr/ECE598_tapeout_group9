module butterfly_xbar_out_tb();

    /////////////////////////////////////////
    // Set up signals

    logic clk;
    logic resetn;

    logic [9:0] stride;
    logic [127:0] read1;
    logic [127:0] read2;
    logic [31:0] butterfly_top1, butterfly_top2, butterfly_top3, butterfly_top4;
    logic [31:0] butterfly_bot1, butterfly_bot2, butterfly_bot3, butterfly_bot4;

    /////////////////////////////////////////
    // SDF annotation
    `ifdef SYN
        initial $sdf_annotate("../../syn/butterfly_xbar/butterfly_xbar.syn.sdf", butterfly_xbar_tb.dut);
    `endif

    /////////////////////////////////////////
    // Set up DUT

    butterfly_xbar_out dut (
        .i_STRIDE(stride),

        .i_BUTTERFLY_1_TOP(butterfly_top1),
        .i_BUTTERFLY_2_TOP(butterfly_top2),
        .i_BUTTERFLY_3_TOP(butterfly_top3),
        .i_BUTTERFLY_4_TOP(butterfly_top4),

        .i_BUTTERFLY_1_BOTTOM(butterfly_bot1),
        .i_BUTTERFLY_2_BOTTOM(butterfly_bot2),
        .i_BUTTERFLY_3_BOTTOM(butterfly_bot3),
        .i_BUTTERFLY_4_BOTTOM(butterfly_bot4),

        .o_READ_OUTPUT1(read1),
        .o_READ_OUTPUT2(read2)

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
        $display("\n[MONITOR] Time | stride | top1 | top2 | top3 | top4 | bot1 | bot2 | bot3 | bot4 | read1 | read2 | ");
        $display("-----------------------------------------------------------------------");

        // $monitor runs in the background for the entire simulation
        $monitor("%8t | %d | %h | %h | %h | %h | %h | %h | %h | %h | %h | %h", 
                 $time, 
                 stride,
                 butterfly_top1, 
                 butterfly_top2, 
                 butterfly_top3,
                 butterfly_top4,
                 butterfly_bot1, 
                 butterfly_bot2, 
                 butterfly_bot3,
                 butterfly_bot4,
                 read1, 
                 read2
                 );

        // Start
        stride = 8;
        butterfly_top1 = 32'h11111111;
        butterfly_top2 = 32'h22222222;
        butterfly_top3 = 32'h33333333;
        butterfly_top4 = 32'h44444444;
        butterfly_bot1 = 32'hAAAAAAAA;
        butterfly_bot2 = 32'hBBBBBBBB;
        butterfly_bot3 = 32'hCCCCCCCC;
        butterfly_bot4 = 32'hDDDDDDDD;
        #10;
        stride = 2;
        #10;
        stride = 1;
        #10 ;
        stride = 0;
        $finish;
    end

endmodule