//`timescale 1ns/1ps
`timescale 1ns/1ps
// 4X4 Array
module top_tb;
   // universal
    int file;
    logic clk;
    logic rst_n;
    logic scan_id;

    // ------------------------------------------------------
    // Scan pad signals
    // ------------------------------------------------------
    logic scan_phi;
    logic scan_phi_bar;
    logic scan_data_in;
    logic scan_data_out;
    logic scan_load_chip;
    logic scan_load_chain;


   clk_gen c1 (.clk(clk), .rst_n(rst_n));

   top_scan ts1 (
    .clk(clk),
    .rst_n(rst_n),
    .scan_phi(scan_phi),
    .scan_phi_bar(scan_phi_bar),
    .scan_data_in(scan_data_in),
    .scan_load_chip(scan_load_chip),
    .scan_load_chain(scan_load_chain),
    .scan_data_out(scan_data_out),
    .scan_id(scan_id)
    );

   top dut (
        .clk(clk),
        .rst_n(rst_n),

        // Pads
        .scan_id(scan_id),
        .scan_phi(scan_phi),
        .scan_phi_bar(scan_phi_bar),
        .scan_data_in(scan_data_in),
        .scan_data_out(scan_data_out),
        .scan_load_chip(scan_load_chip),
        .scan_load_chain(scan_load_chain)
    );


   initial begin

    //this is cause we want to keep reading from the start status register.
    //start_ctrl_ren_from_core = 1;
      file = $fopen("scan_data_out.txt", "w");
      `ifdef FSDB_DUMP
      $fsdbDumpfile("top_tb.fsdb");
      $fsdbDumpvars(0, top_tb, "+struct");
      $fsdbDumpvars("+mda");
      `endif
      #(353*`CLK_CYCLE);

      
      #(1000000*`CLK_CYCLE);
      $finish();
   end

   always begin
      `SCAN_DELAY
      `SCAN_DELAY
      `SCAN_DELAY
      `SCAN_DELAY
      `SCAN_DELAY
      $fwrite(file, "%b", scan_data_out);
   end


endmodule
