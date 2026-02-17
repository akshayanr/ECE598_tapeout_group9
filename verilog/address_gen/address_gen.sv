module address_gen(
    input clk,
    input i_resetn, 

    input i_working,
    input [9:0] i_calcs_per_group,
    input [7:0] i_stride_idx_offset,
    input [7:0] i_group_offset,
    input i_new_stage_trigger,

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


    assign new_group_trigger  = (group_calc_counter == i_calcs_per_group);
    assign address_offset     = (i_stride_idx_offset == 0) ? 1 : i_stride_idx_offset;
    assign address_increment  = new_group_trigger ? i_group_offset : 1;

    integer i;

    always_ff @(posedge clk or negedge i_resetn) begin
        if(i_new_stage_trigger || !i_resetn) begin
            address1          <= 0; 
            address2          <= 0; 
        end else begin
            address1          <= address1 + address_increment; 
            address2          <= address1 + address_increment + address_offset;
        end

        if((new_group_trigger || !i_resetn)) begin
            group_calc_counter <= 0;
        end else if(i_working == 1) begin
            group_calc_counter <= group_calc_counter + 4;
        end else begin
            group_calc_counter <= group_calc_counter;
        end

    end

endmodule