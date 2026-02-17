`timescale 1ns/1ps

// thanks gemini
module tb_fft_top();

    // -------------------------------------------------------------------------
    // 1. Signals & Configuration
    // -------------------------------------------------------------------------
    logic clk;
    logic rstn;
    
    // DUT Inputs
    logic       i_working;
    logic [2:0] i_point_config;
    logic [127:0] i_rdata1;
    logic [127:0] i_rdata2;
    
    // DUT Outputs
    logic       o_fft_done;
    logic [7:0] o_raddress1, o_raddress2;
    logic [7:0] o_waddress1, o_waddress2;
    logic [127:0] o_wdata1, o_wdata2;
    logic       o_global_write_enable;
    logic       o_sram_read_register; // (Unused in TB, but good for debug)

    // Simulation Memory (SRAM Model)
    // 256 depth x 128 width
    logic [127:0] sram [0:255]; 

    // File Handles
    integer f_out_check;
    integer status;
    
    // -------------------------------------------------------------------------
    // 2. DUT Instantiation
    // -------------------------------------------------------------------------
    fft_top dut (
        .clk(clk),
        .rstn(rstn),
        .i_working(i_working),
        .i_point_config(i_point_config),
        .o_fft_done(o_fft_done),
        
        .o_raddress1(o_raddress1), 
        .o_raddress2(o_raddress2),
        .i_rdata1(i_rdata1),       
        .i_rdata2(i_rdata2),
        
        .o_waddress1(o_waddress1), 
        .o_waddress2(o_waddress2),
        .o_wdata1(o_wdata1),       
        .o_wdata2(o_wdata2),
        .o_global_write_enable(o_global_write_enable),
        .o_sram_read_register(o_sram_read_register)
    );

    // -------------------------------------------------------------------------
    // 3. Clock & Setup
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #(`CLK_PERIOD_HALF) clk = ~clk; // 100MHz clock

    initial begin
        // A. Load Memory from Input File
        // We use $readmemh because your input format is raw hex strings
        $readmemh("mem_init.txt", sram);
        $display("SRAM initialized from 'mem_init.txt'.");

        // B. Open Expected Output File
        f_out_check = $fopen("mem_writes.txt", "r");
        if (!f_out_check) begin
            $display("Error: Could not open 'mem_writes.txt'");
            $finish;
        end

        // C. Reset Sequence
        rstn = 0;
        i_working = 0;
        i_point_config = 3'b000; // Set your config (e.g., 0 for 8-point, etc.)
        
        repeat(5) @(posedge clk);
        rstn = 1;
        
        // D. Start FFT
        @(posedge clk);
        i_working = 1;
        $display("Starting FFT execution...");

        // E. Wait for Completion
        wait(o_fft_done);
        repeat(5) @(posedge clk);
        
        $display("FFT Done signal received. Test Complete.");
        $fclose(f_out_check);
        $finish;
    end

    // -------------------------------------------------------------------------
    // 4. SRAM Model (Read/Write Logic)
    // -------------------------------------------------------------------------
    
    // Synchronous Read (1 cycle latency to match block RAM)
    always @(posedge clk) begin
        if (!rstn) begin
            i_rdata1 <= 128'h0;
            i_rdata2 <= 128'h0;
        end else begin
            // Whenever DUT outputs an address, the SRAM provides data in the NEXT cycle
            i_rdata1 <= sram[o_raddress1];
            i_rdata2 <= sram[o_raddress2];
        end
    end

    // Synchronous Write (Update local memory)
    always @(posedge clk) begin
        if (o_global_write_enable) begin
            sram[o_waddress1] <= o_wdata1;
            sram[o_waddress2] <= o_wdata2;
        end
    end

    // -------------------------------------------------------------------------
    // 5. Output Checker
    // -------------------------------------------------------------------------
    // This block triggers ONLY when the DUT writes data.
    // It reads the next 2 lines from the text file and compares them.
    
    reg [31:0] exp_addr;
    reg [31:0] exp_d3, exp_d2, exp_d1, exp_d0; // 32-bit chunks
    logic [127:0] full_exp_data;

    task check_port(input [7:0] dut_addr, input [127:0] dut_data, input string port_name);
        // Read one line from file: "Addr Chunk3 Chunk2 Chunk1 Chunk0"
        status = $fscanf(f_out_check, "%d %h %h %h %h\n", exp_addr, exp_d3, exp_d2, exp_d1, exp_d0);
        
        if (status != 5) begin
            $display("[ERROR] End of expected file reached prematurely or format error!");
            $finish;
        end

        full_exp_data = {exp_d3, exp_d2, exp_d1, exp_d0};

        // 1. Check Address
        if (dut_addr !== exp_addr[7:0]) begin
             $display("[%t] [FAIL] %s Address Mismatch! Expected: %d, Got: %d", 
                      $time, port_name, exp_addr, dut_addr);
        end

        // 2. Check Data (Bitwise Exact)
        if (dut_data !== full_exp_data) begin
            $display("[%t] [FAIL] %s Data Mismatch at Addr %d", $time, port_name, dut_addr);
            $display("   Expected: %h %h %h %h", exp_d3, exp_d2, exp_d1, exp_d0);
            $display("   Got:      %h %h %h %h", dut_data[127:96], dut_data[95:64], dut_data[63:32], dut_data[31:0]);
        end else begin
            $display("[%t] [PASS] %s Write Addr %d OK", $time, port_name, dut_addr);
        end
    endtask

    always @(posedge clk) begin
        if (o_global_write_enable) begin
            // The output file lists outputs sequentially.
            // Assumption: The file lists Port 1's write first, then Port 2's write.
            // Adjust order below if your file is "Port 2 then Port 1".
            $display("Write!");
            check_port(o_waddress1, o_wdata1, "Port 1");
            check_port(o_waddress2, o_wdata2, "Port 2");
        end
    end

endmodule