// Synchronizer and pulse generator 
// id_valid asserts for exactly one clock cycle when a toggle is detected
// The pulse is generated on either rising or falling edge of scan_id
module syn_pulse_gen (
    input  clk,
    input  rst_n,
    input  scan_id,
    output reg  id_valid
);

   reg scan_id_d;
   reg scan_id_2d;
   reg id_hold;
   reg id_hold_w;

   // Synchronizer and state register
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         scan_id_d  <= 1'b0;
         scan_id_2d <= 1'b0;
         id_hold    <= 1'b0;
      end
      else begin
         scan_id_d  <= scan_id;
         scan_id_2d <= scan_id_d;
         id_hold    <= id_hold_w;
      end
   end

   // Pulse generation logic
   always @* begin
      id_valid  = 1'b0;
      id_hold_w = id_hold;

      if (scan_id_2d != id_hold) begin
         id_valid  = 1'b1;        // one-cycle pulse
         id_hold_w = scan_id_2d;  // update stored value
      end
   end

endmodule
