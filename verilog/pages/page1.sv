module page1(
    input [2:0] i_point_configuration, 
    input clock, 
    input [9:0] i_reset, 
    input i_working,

    output o_calcs_per_group, 
    output o_stride_index_offset, 
    output o_stride, 
    output o_group_offset 

); 


    logic [9:0] count_value; 
    wire  [9:0] count_value_comb;

    wire [9:0] reset_input_calcs;
    wire [9:0] reset_input_stride;
    wire [9:0] reset_input_group_offset;
    wire [9:0] group_offset_compare; 

    wire [9:0] calcs_and_stride 
    wire new_stage_trigger; 

    logic [9:0] reg_train1; 
    logic [9:0] reg_train2; 
    logic [9:0] reg_train3; 
    logic [9:0] reg_train4; 
    logic [9:0] reg_train5; 
    logic [9:0] reg_train6; 
    
    assign count_value_comb = count_value;

    assign reset_input_calcs = (4 << i_point_configuration); 
    assign reset_input_stride = (1 << point_configuration);
    assign reset_input_group_offset = (1 + (point_configuration << 1));

    assign calcs_and_stride = new_stage_trigger ? (i_reset >> reset_input_calcs) : i_reset;
    assign o_stride_index_offset = new_stage_trigger ? (i_reset >> reset_input_stride) : i_reset;
    assign o_stride = calcs_and_stride; 
    assign o_calcs_per_group = calcs_and_stride; 

    assign group_offset_compare = new_stage_trigger ? (i_reset - reset_input_group_offset) : i_reset; 
    assign o_group_offset = (group_offset_compare == 2'b11) ? 10'b0000000010 : group_offset_compare;

    assign new_stage_trigger = (reg_train6 == calcs_and_stride);

    always @(posedge clock) begin
        if(i_working && !new_stage_trigger) count_value <= count_value_comb + 3'b100;
        else if(i_working) count_value <= count_value_comb; 
        else count_value <= 0;

        reg_train6 <= reg_train5; 
        reg_train5 <= reg_train4; 
        reg_train4 <= reg_train3; 
        reg_train3 <= reg_train2; 
        reg_train2 <= reg_train1; 
        reg_train1 <= count_value;

    end






endmodule