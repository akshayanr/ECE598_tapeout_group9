`timescale 1ns / 1ps

module tb_mem_interface();

    // ==========================================
    // 1. SYSTEM SIGNALS & STIMULUS
    // ==========================================
    logic clk;
    logic [7:0]   raddress1, raddress2;
    logic [7:0]   waddress1, waddress2;
    logic [127:0] wdata1, wdata2;
    logic         sram_read_register;
    
    wire  [127:0] rdata1, rdata2;

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    // ==========================================
    // 2. SRAM INTERCONNECT WIRES
    // ==========================================
    // SRAM0 Lower (63:0)
    wire SRAM0_BIST0, SRAM0_AWT0, SRAM0_CEBA0, SRAM0_CEBB0, SRAM0_WEBA0, SRAM0_WEBB0;
    wire [7:0] SRAM0_AA0, SRAM0_AB0; // Fixed to 8-bit
    wire [63:0] SRAM0_DA0, SRAM0_DB0, SRAM0_BWEBA0, SRAM0_BWEBB0, SRAM0_QA0, SRAM0_QB0;

    // SRAM0 Upper (127:64)
    wire SRAM0_BIST1, SRAM0_AWT1, SRAM0_CEBA1, SRAM0_CEBB1, SRAM0_WEBA1, SRAM0_WEBB1;
    wire [7:0] SRAM0_AA1, SRAM0_AB1; // Fixed to 8-bit
    wire [63:0] SRAM0_DA1, SRAM0_DB1, SRAM0_BWEBA1, SRAM0_BWEBB1, SRAM0_QA1, SRAM0_QB1;

    // SRAM1 Lower (63:0)
    wire SRAM1_BIST0, SRAM1_AWT0, SRAM1_CEBA0, SRAM1_CEBB0, SRAM1_WEBA0, SRAM1_WEBB0;
    wire [7:0] SRAM1_AA0, SRAM1_AB0; // Fixed to 8-bit
    wire [63:0] SRAM1_DA0, SRAM1_DB0, SRAM1_BWEBA0, SRAM1_BWEBB0, SRAM1_QA0, SRAM1_QB0;

    // SRAM1 Upper (127:64)
    wire SRAM1_BIST1, SRAM1_AWT1, SRAM1_CEBA1, SRAM1_CEBB1, SRAM1_WEBA1, SRAM1_WEBB1;
    wire [7:0] SRAM1_AA1, SRAM1_AB1; // Fixed to 8-bit
    wire [63:0] SRAM1_DA1, SRAM1_DB1, SRAM1_BWEBA1, SRAM1_BWEBB1, SRAM1_QA1, SRAM1_QB1;

    // ==========================================
    // 3. INSTANTIATE DUT (Device Under Test)
    // ==========================================
    mem_interface dut (
        .raddress1(raddress1), .rdata1(rdata1),
        .raddress2(raddress2), .rdata2(rdata2),
        .waddress1(waddress1), .wdata1(wdata1),
        .waddress2(waddress2), .wdata2(wdata2),
        .global_write_enable(1),
        .sram_read_register(sram_read_register),
        
        // SRAM0 Connections
        .SRAM0_BIST0(SRAM0_BIST0), .SRAM0_AWT0(SRAM0_AWT0), .SRAM0_CEBA0(SRAM0_CEBA0), .SRAM0_CEBB0(SRAM0_CEBB0), .SRAM0_WEBA0(SRAM0_WEBA0), .SRAM0_WEBB0(SRAM0_WEBB0),
        .SRAM0_AA0(SRAM0_AA0), .SRAM0_AB0(SRAM0_AB0), .SRAM0_DA0(SRAM0_DA0), .SRAM0_DB0(SRAM0_DB0), .SRAM0_BWEBA0(SRAM0_BWEBA0), .SRAM0_BWEBB0(SRAM0_BWEBB0), .SRAM0_QA0(SRAM0_QA0), .SRAM0_QB0(SRAM0_QB0),
        
        .SRAM0_BIST1(SRAM0_BIST1), .SRAM0_AWT1(SRAM0_AWT1), .SRAM0_CEBA1(SRAM0_CEBA1), .SRAM0_CEBB1(SRAM0_CEBB1), .SRAM0_WEBA1(SRAM0_WEBA1), .SRAM0_WEBB1(SRAM0_WEBB1),
        .SRAM0_AA1(SRAM0_AA1), .SRAM0_AB1(SRAM0_AB1), .SRAM0_DA1(SRAM0_DA1), .SRAM0_DB1(SRAM0_DB1), .SRAM0_BWEBA1(SRAM0_BWEBA1), .SRAM0_BWEBB1(SRAM0_BWEBB1), .SRAM0_QA1(SRAM0_QA1), .SRAM0_QB1(SRAM0_QB1),

        // SRAM1 Connections
        .SRAM1_BIST0(SRAM1_BIST0), .SRAM1_AWT0(SRAM1_AWT0), .SRAM1_CEBA0(SRAM1_CEBA0), .SRAM1_CEBB0(SRAM1_CEBB0), .SRAM1_WEBA0(SRAM1_WEBA0), .SRAM1_WEBB0(SRAM1_WEBB0),
        .SRAM1_AA0(SRAM1_AA0), .SRAM1_AB0(SRAM1_AB0), .SRAM1_DA0(SRAM1_DA0), .SRAM1_DB0(SRAM1_DB0), .SRAM1_BWEBA0(SRAM1_BWEBA0), .SRAM1_BWEBB0(SRAM1_BWEBB0), .SRAM1_QA0(SRAM1_QA0), .SRAM1_QB0(SRAM1_QB0),

        .SRAM1_BIST1(SRAM1_BIST1), .SRAM1_AWT1(SRAM1_AWT1), .SRAM1_CEBA1(SRAM1_CEBA1), .SRAM1_CEBB1(SRAM1_CEBB1), .SRAM1_WEBA1(SRAM1_WEBA1), .SRAM1_WEBB1(SRAM1_WEBB1),
        .SRAM1_AA1(SRAM1_AA1), .SRAM1_AB1(SRAM1_AB1), .SRAM1_DA1(SRAM1_DA1), .SRAM1_DB1(SRAM1_DB1), .SRAM1_BWEBA1(SRAM1_BWEBA1), .SRAM1_BWEBB1(SRAM1_BWEBB1), .SRAM1_QA1(SRAM1_QA1), .SRAM1_QB1(SRAM1_QB1)
    );

    // ==========================================
    // 4. INSTANTIATE SRAMS
    // ==========================================
    insert_real_sram_name sram0_lower (.CLKA(clk), .CLKB(clk), .BIST(SRAM0_BIST0), .AWT(SRAM0_AWT0), .CEBA(SRAM0_CEBA0), .CEBB(SRAM0_CEBB0), .WEBA(SRAM0_WEBA0), .WEBB(SRAM0_WEBB0), .AA(SRAM0_AA0), .AB(SRAM0_AB0), .DA(SRAM0_DA0), .DB(SRAM0_DB0), .BWEBA(SRAM0_BWEBA0), .BWEBB(SRAM0_BWEBB0), .QA(SRAM0_QA0), .QB(SRAM0_QB0));
    insert_real_sram_name sram0_upper (.CLKA(clk), .CLKB(clk), .BIST(SRAM0_BIST1), .AWT(SRAM0_AWT1), .CEBA(SRAM0_CEBA1), .CEBB(SRAM0_CEBB1), .WEBA(SRAM0_WEBA1), .WEBB(SRAM0_WEBB1), .AA(SRAM0_AA1), .AB(SRAM0_AB1), .DA(SRAM0_DA1), .DB(SRAM0_DB1), .BWEBA(SRAM0_BWEBA1), .BWEBB(SRAM0_BWEBB1), .QA(SRAM0_QA1), .QB(SRAM0_QB1));
    insert_real_sram_name sram1_lower (.CLKA(clk), .CLKB(clk), .BIST(SRAM1_BIST0), .AWT(SRAM1_AWT0), .CEBA(SRAM1_CEBA0), .CEBB(SRAM1_CEBB0), .WEBA(SRAM1_WEBA0), .WEBB(SRAM1_WEBB0), .AA(SRAM1_AA0), .AB(SRAM1_AB0), .DA(SRAM1_DA0), .DB(SRAM1_DB0), .BWEBA(SRAM1_BWEBA0), .BWEBB(SRAM1_BWEBB0), .QA(SRAM1_QA0), .QB(SRAM1_QB0));
    insert_real_sram_name sram1_upper (.CLKA(clk), .CLKB(clk), .BIST(SRAM1_BIST1), .AWT(SRAM1_AWT1), .CEBA(SRAM1_CEBA1), .CEBB(SRAM1_CEBB1), .WEBA(SRAM1_WEBA1), .WEBB(SRAM1_WEBB1), .AA(SRAM1_AA1), .AB(SRAM1_AB1), .DA(SRAM1_DA1), .DB(SRAM1_DB1), .BWEBA(SRAM1_BWEBA1), .BWEBB(SRAM1_BWEBB1), .QA(SRAM1_QA1), .QB(SRAM1_QB1));

    // ==========================================
    // 5. TEST SEQUENCE
    // ==========================================
    initial begin
        // Initialize signals
        raddress1 = 0; raddress2 = 0;
        waddress1 = 0; waddress2 = 0;
        wdata1 = 0; wdata2 = 0;
        sram_read_register = 0;

        // Wait for global reset
        #20; 

        // ---------------------------------------------------------
        // PHASE 1: sram_read_register = 0 (Read SRAM0 / Write SRAM1)
        // ---------------------------------------------------------
        @(negedge clk); 
        $display("[%0t] PHASE 1: Setup Write to SRAM1...", $time);
        sram_read_register = 0;
        waddress1 = 8'h1A; wdata1 = 128'hAAAA_AAAA_BBBB_BBBB_CCCC_CCCC_DDDD_DDDD;
        waddress2 = 8'h1B; wdata2 = 128'h1111_2222_3333_4444_5555_6666_7777_8888;
        // The actual write will occur on the upcoming posedge.
        
        // ---------------------------------------------------------
        // PHASE 2: sram_read_register = 1 (Read SRAM1 / Write SRAM0)
        // ---------------------------------------------------------
        @(negedge clk);
        $display("[%0t] PHASE 2: Toggling Buffer. Reading SRAM1, Writing SRAM0...", $time);
        sram_read_register = 1;
        
        // Set Read addresses to what we just wrote to SRAM1
        raddress1 = 8'h1A; raddress2 = 8'h1B;
        
        // Simultaneously write new data to SRAM0
        waddress1 = 8'h2A; wdata1 = 128'hDEAD_BEEF_DEAD_BEEF_0000_0000_1111_1111;
        waddress2 = 8'h2B; wdata2 = 128'hCAFE_BABE_CAFE_BABE_9999_9999_8888_8888;
        // The read & write will process on the upcoming posedge.

        // ---------------------------------------------------------
        // PHASE 3: sram_read_register = 0 (Read SRAM0 / Write SRAM1)
        // ---------------------------------------------------------
        @(negedge clk); 
        // 1. First, safely sample Phase 2's read data AFTER the clock-to-Q delay
        $display("   Read Data 1 from SRAM1: %h", rdata1);
        $display("   Read Data 2 from SRAM1: %h", rdata2);

        // 2. Then, set up the next flip
        $display("[%0t] PHASE 3: Toggling Buffer Back. Reading SRAM0...", $time);
        sram_read_register = 0;
        
        // Set Read addresses to what we just wrote to SRAM0
        raddress1 = 8'h2A; raddress2 = 8'h2B;

        // ---------------------------------------------------------
        // FINAL SAMPLE
        // ---------------------------------------------------------
        @(negedge clk);
        // Safely sample Phase 3's read data
        $display("   Read Data 1 from SRAM0: %h", rdata1);
        $display("   Read Data 2 from SRAM0: %h", rdata2);

        #20;
        $display("[%0t] Test Finished.", $time);
        $finish;
    end

endmodule
