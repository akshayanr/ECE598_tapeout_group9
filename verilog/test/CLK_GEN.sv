`timescale 1ps/1fs
`define CLK_CYCLE      10000 
`define SETUP_CYCLE    0.1
`define RESET_CYCLE    10

program automatic  clk_gen # 
(
   CLK_CYCLE   = `CLK_CYCLE,
   RESET_CYCLE = `RESET_CYCLE
)
(
   output   logic   clk,
   output   logic   rst_n
);

   logic clk_gate;

   logic int_clk;

   initial clk_gate = 0;

   assign clk = int_clk && clk_gate;


   initial begin
      int_clk = 0;
      # (`CLK_CYCLE * 5.0)
      forever begin
         # (CLK_CYCLE / 2.0)
         int_clk = ~int_clk; 
      end
   end

   initial begin
      rst_n = 1;
      # (`CLK_CYCLE * 5.0)
      rst_n = 0;
      # (`CLK_CYCLE * (RESET_CYCLE - 6))
      rst_n = 1;
      #(2*`CLK_CYCLE)
      clk_gate = 1;
   end


endprogram

   logic dummy;
   
   task delay_cycle ();
  
      input real number;
      begin
         #(number * `CLK_CYCLE)
         $display("delay %g cycles", number);
      //   dummy = 1;
      end
   endtask
