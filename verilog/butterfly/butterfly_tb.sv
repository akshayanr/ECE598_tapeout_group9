
module butterfly_tb();

   /////////////////////////////////////////
   // Set up signals
   logic clk;
   logic [15:0] real_a_in;
   logic [15:0] imag_a_in;
   logic [15:0] real_b_in;
   logic [15:0] imag_b_in;
   logic [15:0] real_a_out;
   logic [15:0] imag_a_out;
   logic [15:0] real_b_out;
   logic [15:0] imag_b_out;

   logic [15:0] read_val0;
   logic [15:0] read_val1;
   logic [15:0] read_val2;
   logic [15:0] read_val3;
   logic [15:0] tmp0;
   logic [15:0] tmp1;
   logic [15:0] tmp2;
   logic [15:0] tmp3;
   logic [15:0] write_val0;
   logic [15:0] write_val1;
   logic [15:0] write_val2;
   logic [15:0] write_val3;


   /////////////////////////////////////////
   // SDF annotation
   `ifdef SYN
      initial $sdf_annotate("../../syn/butterfly/butterfly.syn.sdf", butterfly_tb.dut);
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
      read_file  = $fopen("butterfly_gb.txt", "r");
      write_file = $fopen("butterfly_tb.txt", "w");
      @(posedge clk);

      // Read the stimulus and write the outputs until we run out of inputs
      while(!$feof(read_file)) begin
         @(negedge clk);
         $fscanf(read_file, "%b %b %b %b | %b %b %b %b\n", 
                 read_val0, read_val1, read_val2, read_val3, 
                 tmp0, tmp1, tmp2, tmp3);
         $fdisplay(write_file, "%b %b %b %b | %b %b %b %b", 
                  read_val0, read_val1, read_val2, read_val3,
                  write_val0, write_val1, write_val2, write_val3);
      end

      // Close the files
      $fclose(read_file);
      $fclose(write_file);
      $finish;
      
   end

   /////////////////////////////////////////
   // Set up DUT

   butterfly dut (
      .i_clk(clk),
      .i_a({real_a_in, imag_a_in}),
      .i_b({real_b_in, imag_b_in}),
      .o_a({real_a_out, imag_a_out}),
      .o_b({real_b_out, imag_b_out})
   );

   /////////////////////////////////////////
   // Run Simulation

   always #`CLK_PERIOD_HALF clk = ~clk;

   // Use this to align the inputs/outputs with clock edge properly
   always @(posedge clk) begin
      real_a_in  <= read_val0;
      imag_a_in  <= read_val1;
      real_b_in  <= read_val2;
      imag_b_in  <= read_val3;

      write_val0 <= real_a_out;
      write_val1 <= imag_a_out;
      write_val2 <= real_b_out;
      write_val3 <= imag_b_out;

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

