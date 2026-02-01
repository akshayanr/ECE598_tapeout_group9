
module mult_tb();

   /////////////////////////////////////////
   // Set up signals
   logic clk;
   logic [15:0] real_mcand;
   logic [15:0] imag_mcand;
   logic [15:0] real_mplier;
   logic [15:0] imag_mplier;
   logic [15:0] real_out;
   logic [15:0] imag_out;

   logic [15:0] read_val0;
   logic [15:0] read_val1;
   logic [15:0] read_val2;
   logic [15:0] read_val3;
   logic [15:0] tmp0;
   logic [15:0] tmp1;
   logic [15:0] write_val0;
   logic [15:0] write_val1;


   /////////////////////////////////////////
   // SDF annotation
   `ifdef SYN
      initial $sdf_annotate("../../syn/mult/mult.syn.sdf", mult_tb.dut);
   `endif


   /////////////////////////////////////////
   // Do file IO
   integer read_file;
   integer write_file;
   
   initial begin
            
      // Setup dumpfiles
      // $dumpfile( "filename.dump" );
      // $dumpvars( 0, butterfly_tb );

      // Open the stimulus and output files
      read_file  = $fopen("mult_gb.txt", "r");
      write_file = $fopen("mult_tb.txt", "w");
      @(posedge clk);

      // Read the stimulus and write the outputs until we run out of inputs
      while(!$feof(read_file)) begin
         @(negedge clk);
         $fscanf(read_file, "%b %b %b %b | %b %b\n", 
                 read_val0, read_val1, read_val2, read_val3, 
                 tmp0, tmp1);
         $fdisplay(write_file, "%b %b %b %b | %b %b", 
                  read_val0, read_val1, read_val2, read_val3,
                  write_val0, write_val1);
      end

      // Close the files
      $fclose(read_file);
      $fclose(write_file);
      $finish;
      
   end

   /////////////////////////////////////////
   // Set up DUT

   mult dut (
      .i_clk(clk),
      .i_mcand({real_mcand, imag_mcand}),
      .i_mplier({real_mplier, imag_mplier}),
      .o_result({real_out, imag_out})
   );

   /////////////////////////////////////////
   // Run Simulation

   always #`CLK_PERIOD_HALF clk = ~clk;

   // Use this to align the inputs/outputs with clock edge properly
   always @(posedge clk) begin
      real_mcand   <= read_val0;
      imag_mcand   <= read_val1;
      real_mplier  <= read_val2;
      imag_mplier  <= read_val3;

      write_val0 <= real_out;
      write_val1 <= imag_out;
   end
   initial begin

      // Start
      clk = 0;
      // Go until we've read all the file stimulus
      while(1) begin
         #100;
      end
   end
endmodule // mult_testbench

