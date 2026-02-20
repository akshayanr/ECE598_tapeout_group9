//selects the appropriate SRAM to read from.
//figure out how to enable the ceb and web signals via this module look at how its done in core.
module sram_ping_pong_selector(
    input core_done, //from the core
    input sram_ren, //read enable signal from core: need to figure out whether to enable the read signal for sram A or B.
    input curr_read_sram, //the sram that is designated as read.
    input [127:0] sram_A_rdata, //the read data from sram A
    input [127:0] sram_B_rdata, //the read data from sram B
    input sram_A_ready, //the ready signal from sram A
    input sram_B_ready, //the ready signal from sram B
    output logic sram_ready,
    output logic [127:0] sram_rdata, 
    output logic sram_A_ren, 
    output logic sram_B_ren 
);

// assign read_from_sram = start_fft_signal ? ~read_select_signal : 0;
   //TODO
   assign sram_rdata = core_done ? (curr_read_sram ? sram_A_rdata : sram_B_rdata) : sram_A_rdata;

   //sram_rdata_A need this signal for both.
   //set sram_ready_A
   assign sram_ready = core_done ? (curr_read_sram ? sram_A_ready : sram_B_ready) : sram_A_ready;


   //assign renable signals because we don't want to have to read from these all the time. 
   //if fft started then we read from either A or B, if select_sram_reg == 0, then we have to read from sram B; else read from sram A.
   //read sram_ren_AA
   //SELECT TO READ FROM CORRECT SRAM
   always_comb begin
      if(core_done) begin
         //the most recent read is from sram A, so we need to read from sram B.
         //if select, thwen we want to 
         if(curr_read_sram) begin
            sram_A_ren = sram_ren;
            sram_B_ren = 0;
         end else begin
            //else reverse.
            sram_A_ren = 0;

            sram_B_ren = sram_ren;
         end
      end else begin
         //so in this case; you just want to read from sramA.
         sram_A_ren = sram_ren;

         sram_B_ren = 0;
      end
   end

endmodule