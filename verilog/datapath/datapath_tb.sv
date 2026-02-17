`timescale 1ns/1ps

module tb_datapath();

    parameter BUTTERFLY_DELAY = 2;
    parameter MULT_DELAY      = 3;
    localparam ADDRESS_DELAY  = BUTTERFLY_DELAY + MULT_DELAY;
    
    logic clk;
    wire [7:0] i_addr1;
    wire [7:0] i_addr2;
    logic [127:0] i_data1, i_data2;
    logic [9:0]   i_stride;
    logic [8:0]   tw_off[0:3];
    logic         i_valid;
    
    wire [7:0] o_addr1;
    wire [7:0] o_addr2;
    wire [127:0]  o_data1, o_data2;
    wire          o_valid;

    // DUT instantiation
    datapath #(BUTTERFLY_DELAY, MULT_DELAY) dut (
        .clk(clk),
        .i_data1(i_data1), .i_data2(i_data2),
        .i_addr1(i_addr1), .i_addr2(i_addr2),
        .i_stride(i_stride), .i_valid(i_valid),
        .i_twiddle_offset1(tw_off[0]), .i_twiddle_offset2(tw_off[1]),
        .i_twiddle_offset3(tw_off[2]), .i_twiddle_offset4(tw_off[3]),
        /* Addr ports tied off or monitored as needed */
        .o_data1(o_data1), 
        .o_data2(o_data2), 
        .o_addr1(o_addr1),
        .o_addr2(o_addr2),
        .o_valid(o_valid)
    );

    // Clock gen
    initial clk = 0;
    always #(`CLK_PERIOD_HALF) clk = ~clk;

    // File Handling Variables
    integer in_file, out_file, status;
    logic [31:0] tmp_stride, tmp_d1[0:3], tmp_d2[0:3], tmp_tw[0:3];
    logic [31:0] exp_d1[0:3], exp_d2[0:3];

    initial begin
        // Initialize
        i_valid = 0;
        in_file = $fopen("datapath.in.txt", "r");
        out_file = $fopen("datapath.out.txt", "r");
        
        if (!in_file || !out_file) begin
            $display("Error: Could not open data files.");
            $finish;
        end

        repeat(5) @(posedge clk);

        // --- Input Driving Loop ---
        while (!$feof(in_file)) begin
            // Read 13 hex values per line
            status = $fscanf(in_file, "%d %h %h %h %h %h %h %h %h %h %h %h %h\n", 
                tmp_stride, 
                tmp_d1[0], tmp_d1[1], tmp_d1[2], tmp_d1[3],
                tmp_d2[0], tmp_d2[1], tmp_d2[2], tmp_d2[3],
                tmp_tw[0], tmp_tw[1], tmp_tw[2], tmp_tw[3]
            );

            if (status == 13) begin
                @(posedge clk);
                #1;
                i_valid  = 1;
                i_stride = tmp_stride[9:0];
                // Pack 16-bit chunks into 128-bit buses
                i_data1 = {tmp_d1[3], tmp_d1[2], tmp_d1[1], tmp_d1[0]};
                i_data2 = {tmp_d2[3], tmp_d2[2], tmp_d2[1], tmp_d2[0]};
                tw_off[0] = tmp_tw[0][8:0]; 
                tw_off[1] = tmp_tw[1][8:0];
                tw_off[2] = tmp_tw[2][8:0]; 
                tw_off[3] = tmp_tw[3][8:0];
            end
        end

        @(posedge clk) i_valid = 0;
        repeat(ADDRESS_DELAY + 5) @(posedge clk);
        $fclose(in_file);
        $fclose(out_file);
        $display("Testbench complete.");
        $finish;
    end

    // --- Checker Logic ---
    // Reads expected file whenever o_valid is high
    always @(posedge clk) begin
        if (o_valid) begin
            status = $fscanf(out_file, "%h %h %h %h %h %h %h %h\n",
                exp_d1[0], exp_d1[1], exp_d1[2], exp_d1[3],
                exp_d2[0], exp_d2[1], exp_d2[2], exp_d2[3]
            );
            
            if (o_data1 !== {exp_d1[3], exp_d1[2], exp_d1[1], exp_d1[0]} ||
                o_data2 !== {exp_d2[3], exp_d2[2], exp_d2[1], exp_d2[0]}) begin
                $display("[FAIL] Time %0t | Expected1: %h %h %h %h | Got: %h %h %h %h", 
                          $time, exp_d1[3], exp_d1[2], exp_d1[1], exp_d1[0],
                                 o_data1[127:96], o_data1[95:64], o_data1[63:32], o_data1[31:0]);
                $display("[FAIL] Time %0t | Expected2: %h %h %h %h | Got: %h %h %h %h", 
                          $time, exp_d2[3], exp_d2[2], exp_d2[1], exp_d2[0],
                                 o_data2[127:96], o_data2[95:64], o_data2[63:32], o_data2[31:0]);
            end else begin
                $display("[PASS] Time %0t", $time);
            end
        end
    end

endmodule