module point_config #(
    parameter DELAY = 6
)(
    input clk,
    input i_resetn, 

    input [2:0] i_point_configuration, 
    input i_working,

    output o_new_stage_trigger,
    output [9:0] o_calcs_per_group, 
    output [7:0] o_stride_index_offset, 
    output [9:0] o_stride, 
    output [7:0] o_group_offset 

); 

    logic [9:0] calc_counter; 

    logic [9:0] reset_calcs_stride;
    logic [7:0] reset_stride_idx_offset;
    logic [7:0] reset_group_offset;


    logic [9:0] calcs_stride;
    logic [7:0] stride_idx_offset;
    logic [7:0] group_offset;

    logic new_stage_trigger; 

    logic [9:0] counter_delay_reg [DELAY-1:0];
    
    assign o_calcs_per_group        = calcs_stride; 
    assign o_stride_index_offset    = stride_idx_offset;
    assign o_stride                 = calcs_stride; 
    assign o_group_offset           = group_offset;
    assign o_new_stage_trigger      = new_stage_trigger;

    always_comb  begin
        reset_calcs_stride      = 512;
        reset_stride_idx_offset = 128;
        reset_group_offset      = 15;

        case (i_point_configuration)
            3'b000: reset_calcs_stride = 4;
            3'b001: reset_calcs_stride = 8;
            3'b010: reset_calcs_stride = 16;
            3'b011: reset_calcs_stride = 32;
            3'b100: reset_calcs_stride = 64;
            3'b101: reset_calcs_stride = 128;
            3'b110: reset_calcs_stride = 256;
            3'b111: reset_calcs_stride = 512;
        endcase

        case (i_point_configuration)
            3'b000: reset_stride_idx_offset = 1;
            3'b001: reset_stride_idx_offset = 2;
            3'b010: reset_stride_idx_offset = 4;
            3'b011: reset_stride_idx_offset = 8;
            3'b100: reset_stride_idx_offset = 16;
            3'b101: reset_stride_idx_offset = 32;
            3'b110: reset_stride_idx_offset = 64;
            3'b111: reset_stride_idx_offset = 128;
        endcase

        case (i_point_configuration)
            3'b000: reset_group_offset = 1;
            3'b001: reset_group_offset = 3;
            3'b010: reset_group_offset = 5;
            3'b011: reset_group_offset = 7;
            3'b100: reset_group_offset = 9;
            3'b101: reset_group_offset = 11;
            3'b110: reset_group_offset = 13;
            3'b111: reset_group_offset = 15;
        endcase
    end

    assign new_stage_trigger = (counter_delay_reg[DELAY-1] == reset_calcs_stride);

    integer i;

    always_ff @(posedge clk) begin
        if(i_resetn == 0) begin
            calcs_stride          <= reset_calcs_stride; 
            stride_idx_offset     <= reset_stride_idx_offset;
            group_offset          <= reset_group_offset;
        end else if(new_stage_trigger == 1) begin
            calcs_stride          <= calcs_stride >> 1;
            stride_idx_offset     <= stride_idx_offset >> 1;
            group_offset          <= (group_offset == 3) ? 2 : group_offset - 2;
        end else begin
            calcs_stride          <= calcs_stride; 
            stride_idx_offset     <= stride_idx_offset;
            group_offset          <= group_offset;
        end

        if((!new_stage_trigger == 0) || (i_resetn == 0)) begin
            calc_counter <= 0;
        end else if(i_working == 1) begin
            calc_counter <= calc_counter + 4;
        end else begin
            calc_counter <= calc_counter;
        end

        for(i = 1; i < DELAY; i = i + 1) begin
            counter_delay_reg[i] <= counter_delay_reg[i-1];
        end

        counter_delay_reg[0] <= calc_counter;

    end






endmodule