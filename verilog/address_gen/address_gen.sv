module address_gen(
    input clk,
    input i_resetn, 

    input i_working,
    input [9:0] i_calcs_per_group,
    input [7:0] i_stride_idx_offset,
    input [7:0] i_group_offset,
    input i_new_stage_trigger,
    input i_fft_done,

    output o_group_done, 
    output [7:0] o_address_1,
    output [7:0] o_address_2

); 
    logic new_group_trigger; 

    logic [9:0] group_calc_counter; 

    logic [7:0] address1;
    logic [7:0] address2;
    logic [7:0] address_offset;
    logic [7:0] address_increment;

    

    assign o_group_done = new_group_trigger;
    assign o_address_1  = address1;
    assign o_address_2  = address2;

    assign new_group_trigger  = group_calc_counter >= i_calcs_per_group;
    // Do the +4 here, otherwise in the case where we calculate 1 or 2 groups
    // every cycle the calc counter goes 2 cycles per calculate (does the +4 then checks)
    // Need the new group trigger to appear at the same cycle as the last calc basically
    // in the group
    assign internal_new_group_trigger  = (group_calc_counter + 4) >= i_calcs_per_group;
    assign address_offset     = (i_stride_idx_offset == 0) ? 1 : i_stride_idx_offset;
    assign address_increment  = internal_new_group_trigger ? i_group_offset : 1;

    integer i;

    always_ff @(posedge clk or negedge i_resetn) begin
        if(!i_resetn || i_new_stage_trigger) begin
            address1          <= 0; 
            address2          <= address_offset; 
        end else if(i_working && !i_fft_done)begin
            address1          <= address1 + address_increment; 
            address2          <= address1 + address_increment + address_offset;
        end else begin
            address1 <= address1;
            address2 <= address2;
        end

        if((internal_new_group_trigger || i_new_stage_trigger || !i_resetn)) begin
            group_calc_counter <= 0;
        end else if(i_working && !i_fft_done) begin
            group_calc_counter <= group_calc_counter + 4;
        end else begin
            group_calc_counter <= group_calc_counter;
        end

    end

endmodule