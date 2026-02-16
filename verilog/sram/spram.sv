/*

   Delay 1 single port RAM
   read takes 1 cycle
   write takes 1 cycle
   Revisions:
      10/08/21: First created
      10/12/21: 
         usually SRAMS are not reset
         for APR purposes, reset's existence is better
*/

module spram 
#( parameter  WIDTH = 32,
   parameter  SIZE  = 2048
)
(
   input                          clk,
   input                          rst_n,
   input                          wen,
   input                          ren,
   input  [$clog2(SIZE) - 1 : 0]  waddr,
   input  [$clog2(SIZE) - 1 : 0]  raddr,
   input  [WIDTH - 1 : 0]         wdata,
   output logic [WIDTH - 1 : 0]   rdata,
   output logic                   ready
);
   logic [WIDTH - 1 : 0] rdata_pre;
   logic [SIZE - 1 : 0][WIDTH - 1 : 0] entry, entry_w;
   logic real_ren, real_wen;
 
   // SRAM write 
   assign real_wen = wen == 1;

   always_comb begin
      entry_w = entry;
      if (real_wen == 1) entry_w [waddr] = wdata;
   end

  always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         entry <= 0;
      end
      else begin
         entry <= entry_w;
      end
   end 

   // Handshake
   // Read data when ren is asserted 
   assign real_ren = ren == 1;
   assign rdata_pre = (real_ren == 1) ? entry[raddr] : 0;

   logic ready_w;
   assign ready_w = (real_ren == 1)? 1 : 0;   
  
   // When read is done, assert read for one cycle
   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         rdata <= 0;
         ready <= 0;
      end
      else begin
         rdata <= rdata_pre;
         ready <= ready_w;
      end
   end

endmodule 
