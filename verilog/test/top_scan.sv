`timescale 1ns/1ps
`define SCAN_DELAY #500

module top_scan(
   input               clk,
   input               rst_n,
   output   logic      scan_phi,
   output   logic      scan_phi_bar,
   output   logic      scan_data_in,
   output   logic      scan_load_chip,
   output   logic      scan_load_chain,
   input               scan_data_out,
   output   logic      scan_id,
   input               core_done
);
   
   // Scan
   initial scan_phi = 0;
   initial scan_phi_bar = 0;
   initial scan_data_in = 0;
   initial scan_load_chip = 0;
   initial scan_load_chain = 0;
   initial scan_id = 0;

   integer log_file;
   integer output_file;
   //-----------------------------------------
   //  Scan Chain Registers and Tasks
   //-----------------------------------------

   // Scan Registers and Initializations
   
`define SCAN_CHAIN_LENGTH 87

   reg [1-1:0] static_wen;
   reg [1-1:0] static_wen_read;
   initial static_wen      = 1'd0;
   initial static_wen_read = 1'd0;
   reg [1-1:0] static_ren;
   reg [1-1:0] static_ren_read;
   initial static_ren      = 1'd0;
   initial static_ren_read = 1'd0;
   reg [20-1:0] static_addr;
   reg [20-1:0] static_addr_read;
   initial static_addr      = 14'd0;
   initial static_addr_read = 14'd0;
   reg [32-1:0] static_wdata;
   reg [32-1:0] static_wdata_read;
   initial static_wdata      = 32'd0;
   initial static_wdata_read = 32'd0;
   reg [32-1:0] static_rdata;
   reg [32-1:0] static_rdata_read;
   initial static_rdata      = 32'd0;
   initial static_rdata_read = 32'd0;
   reg [1-1:0] static_ready;
   reg [1-1:0] static_ready_read;
   initial static_ready      = 1'd0;
   initial static_ready_read = 1'd0;

   // read in mem values
    logic [31:0] mem [0:1023];
   //logic [127:0] mem [0:255];

   initial begin
      $readmemh("golden.in.txt", mem);
   end

   // Scan chain tasks
   
   task load_chip;
      begin
         `SCAN_DELAY scan_load_chip = 1;
         `SCAN_DELAY scan_load_chip = 0;
         `SCAN_DELAY;
         `SCAN_DELAY;
         `SCAN_DELAY;
      end
   endtask

   task load_chain;
      begin
         `SCAN_DELAY scan_load_chain = 1;
         `SCAN_DELAY scan_phi = 1;
         `SCAN_DELAY scan_phi = 0;
         `SCAN_DELAY scan_phi_bar = 1;
         `SCAN_DELAY scan_phi_bar = 0;
         `SCAN_DELAY scan_load_chain = 0;
         `SCAN_DELAY;
         `SCAN_DELAY;
         `SCAN_DELAY;
         `SCAN_DELAY;
      end
   endtask

   task rotate_chain;
      
      integer i;
      
      reg [`SCAN_CHAIN_LENGTH-1:0] data_in;
      reg [`SCAN_CHAIN_LENGTH-1:0] data_out;
      
      begin
         data_in[0:0] = static_wen;
         data_in[1:1] = static_ren;
         data_in[21:2] = static_addr;
         data_in[53:22] = static_wdata;
         data_in[85:54] = static_rdata;
         data_in[86:86] = static_ready;

         for (i = 0; i < `SCAN_CHAIN_LENGTH; i=i+1) begin
            scan_data_in = data_in[0];
            data_out     = {scan_data_out, data_out[`SCAN_CHAIN_LENGTH-1:1]};
            `SCAN_DELAY scan_phi = 1;
            `SCAN_DELAY scan_phi = 0;
            `SCAN_DELAY scan_phi_bar = 1;
            `SCAN_DELAY scan_phi_bar = 0;
            `SCAN_DELAY data_in = data_in >> 1;
         end

         static_wen_read = data_out[0:0];
         static_ren_read = data_out[1:1];
         static_addr_read = data_out[21:2];
         static_wdata_read = data_out[53:22];
         static_rdata_read = data_out[85:54];
         static_ready_read = data_out[86:86];
      end
      
   endtask

   task write_stuff ();
      input [19:0]   addr_in;
      input [31:0]  wdata_in;
      begin
         static_wen = 1;
         static_ren = 0;
         static_addr = addr_in;
         static_wdata = wdata_in;
         static_rdata = 0;
         static_ready = 0;
         rotate_chain();
         load_chip();
         @(negedge clk);
         @(negedge clk);
         @(negedge clk);
         @(negedge clk);
         @(negedge clk);
         scan_id = ~scan_id;
      end 
   endtask
   
   logic dummy;

   task read_stuff ();
      input [19:0]  addr_in; // modify
      begin
         static_wen = 0;
         static_ren = 1;
         static_addr = addr_in;
         static_wdata = 0;
         static_rdata = 0;
         static_ready = 0;
         rotate_chain();
         load_chip();
         repeat(4) begin
         @(negedge clk);
         dummy = 1;
         end
         scan_id = ~scan_id;
         repeat(20) begin
         @(negedge clk);
         dummy = 1;
         end
         load_chain();
         rotate_chain();
         $fwrite(log_file, "%h %b\n", static_rdata_read, static_ready_read);
      end 
   endtask
  
   logic [9:0] sram_addr;
   logic [19:0] full_addr;
   logic [19:0] point_addr;
   logic [19:0] start_addr;
   logic [19:0] reset_addr;
   logic [19:0] done_addr;
   logic [19:0] cycle_addr;
   logic [31:0] done_rdata;

   // addr = {FILLER | SRAM/REG | sram_addr/*_REG}
   localparam FILLER    = 9'b000000000;
   localparam SRAM      = 1'b0;
   localparam REG       = 1'b1;
   localparam POINT_REG = 10'b1000000000;
   localparam START_REG = 10'b0100000000;
   localparam RESET_REG = 10'b0010000000;
   localparam DONE_REG  = 10'b0001000000;
   localparam CYCLE_REG = 10'b0000100000;


   initial begin
      log_file = $fopen("scan_data_log.txt", "w");
      output_file  = $fopen("fft_out.txt", "w");
      
      point_addr = {FILLER, REG, POINT_REG};
      start_addr = {FILLER, REG, START_REG};
      reset_addr = {FILLER, REG, RESET_REG};
      done_addr  = {FILLER, REG, DONE_REG};
      cycle_addr = {FILLER, REG, CYCLE_REG};

      #(`RESET_CYCLE*`CLK_CYCLE);
      dummy = 1;
 
      // write to reset fft reg (active low)
      write_stuff (reset_addr, 32'h0);
      #(10*`CLK_CYCLE);

      //read reset fft reg
      read_stuff (reset_addr);
      #(10*`CLK_CYCLE);

      // set to 7 or N-point config
      write_stuff (point_addr, $clog2(`NUM_POINTS)-3);
      #(10*`CLK_CYCLE);

      // check that N-point config is set
      read_stuff (point_addr);
      #(10*`CLK_CYCLE);
      
      //toggle reset fft off because we don't want reset.
      write_stuff (reset_addr, 32'h1);
      #(10*`CLK_CYCLE);

      //read reset fft reg to check that it is toggled off.
      read_stuff (reset_addr);
      #(10*`CLK_CYCLE);

      //should read that point config is 0 or at 8-point config
      // read_stuff (point_addr);
      // #(10*`CLK_CYCLE);
      

      // write sram values
      for (int i = 0; i < `NUM_POINTS; ++i) begin
            write_stuff(i, mem[i]);
            #(10*`CLK_CYCLE);
      end


      // read back SRAM values
      for (int i = 0; i < `NUM_POINTS; ++i) begin
         read_stuff(i);
         #(10*`CLK_CYCLE);
      end

      // for (int i = 0; i < 2; ++i) begin
      //    for (int j = 0; j < 4; ++j) begin
      //       write_stuff(i*4 + j, mem[i][j*32 +: 32]);
      //       #(10*`CLK_CYCLE);
      //    end
      // end


      // // read back SRAM values
      // for (int i = 0; i < 2; ++i) begin
      //    for (int j = 0; j < 4; ++j) begin
      //       read_stuff(i*4 + j);
      //       #(10*`CLK_CYCLE);
      //    end
      // end

      // write to start fft reg
      write_stuff (start_addr, 32'h1);
      #(10*`CLK_CYCLE);

      // read to check start fft reg
      read_stuff (start_addr);
      #(10*`CLK_CYCLE);

      // Poll the done bit until its done
      done_rdata = 0;
      while(done_rdata == 0) begin
         read_stuff(done_addr);
         done_rdata = static_rdata_read;
         #(10*`CLK_CYCLE);
      end

      #(10*`CLK_CYCLE);

      // Read the fft results
      for (int i = 0; i < `NUM_POINTS; ++i) begin
         read_stuff(i);
         $fwrite(output_file, "%h\n", static_rdata_read);
         #(10*`CLK_CYCLE);
      end
      $finish();
   end
 
endmodule // tbench	
