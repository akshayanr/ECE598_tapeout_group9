// Thanks gemini
module full_butterfly_tb();

    // Parameters
    parameter BUTTERFLY_STAGES = 2;
    parameter MULT_STAGES      = 3;
    parameter CLK_PERIOD       = 10;

    // DUT Signals
    logic clk;
    logic [31:0] i_butterfly_top;
    logic [31:0] i_butterfly_bot;
    logic [8:0] i_twiddle_addr;
    logic i_valid;

    wire [31:0] o_butterfly_top;
    wire [31:0] o_butterfly_bot;

    // Instantiate the Unit Under Test (UUT)
    full_butterfly #(
        .BUTTERFLY_STAGES(BUTTERFLY_STAGES),
        .MULT_STAGES(MULT_STAGES)
    ) dut (
        .clk(clk),
        .i_butterfly_top(i_butterfly_top),
        .i_butterfly_bot(i_butterfly_bot),
        .i_twiddle_addr(i_twiddle_addr),
        .i_valid(i_valid),

        .o_butterfly_top(o_butterfly_top),
        .o_butterfly_bot(o_butterfly_bot)
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Helper task to drive inputs
    task drive_input(input [31:0] top, input [31:0] bot, input [8:0] twid_addr, input valid);
        @(posedge clk);
        #1; // Drive slightly after clock edge
        i_butterfly_top = top;
        i_butterfly_bot = bot;
        i_twiddle_addr  = twid_addr;
        i_valid = valid;
    endtask

    // Main Test Procedure
    initial begin
        // Initialize
        i_butterfly_top = 0;
        i_butterfly_bot = 0;
        i_twiddle_addr  = 0;
        i_valid         = 0;

        // Reset period (if your modules had reset)
        repeat(5) @(posedge clk);

        // --- Test Case 1: Simple Pass-through / Basic Calculation ---
        // Let's assume FP16 values in hex for simplicity
        // Top = 1.0 (0x3C00), Bot = 0.5 (0x3800), Twiddle = 1.0 (0x3C00)
        drive_input(32'h3C00_3C00, 32'h3800_3800, 0, 1);
        // Outputs = 0x3e003e00 0x380038000 (1+1j, 0.5+0.5j)
        
        // --- Test Case 2 ---
        // Inputs (2+2j, 1+1j, 0-1j)
        drive_input(32'h4000_4000, 32'h3C00_3C00, 256, 1);
        // Outputs = 0x42004200 0xbc00bc000 (3+3j, 1-1j)

        // --- Test Case 3 ---
        // Inputs (2+2j, 1+1j, 0-1j)
        drive_input(32'h4000_4000, 32'h3C00_3C00, 128, 0);
        // Outputs = 0x42004200 0xbc00bc000 (3+3j, 1-1j)

        // --- Test Case 3 ---
        // Inputs (1+1j, 0+0j, sqrt(2) + sqrt(2)j)
        drive_input(32'h3C00_3C00, 32'h0000_0000, 128, 1);
        // Outputs 0x3c003c00 0x3da80000 (1+1j, 2sqrt(2) + 0j)

        // Clear inputs and wait for pipeline to flush
        drive_input(0, 0, 0, 0);
        
        // The total latency is BUTTERFLY_STAGES + MULT_STAGES
        repeat(BUTTERFLY_STAGES + MULT_STAGES + 2) @(posedge clk);

        $display("Simulation Finished");
        $finish;
    end

    // Monitor Outputs
    initial begin
        $monitor("Time=%0t | In_Top=%h In_Bot=%h | Out_Top=%h Out_Bot=%h", 
                 $time, i_butterfly_top, i_butterfly_bot, o_butterfly_top, o_butterfly_bot);
    end

endmodule