module point_config #(
    // Want this to match the time it takes for data to exit the datapath and be written
    parameter DELAY = 5
)(
    input clk,
    input i_resetn, 

    input [2:0] i_point_configuration, 
    input i_working,

    output o_new_stage_trigger,
    output o_sram_read_register,
    output o_valid_data,
    output o_fft_done,
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
    // Algo fix
    logic [7:0] internal_group_offset;

    logic new_stage_trigger; 
    logic sram_read_register;
    logic valid_data;
    logic fft_done;
    logic [DELAY-1:0] fft_done_delay;

    logic [9:0] counter_delay_reg [DELAY-1:0];
    
    assign o_calcs_per_group        = calcs_stride; 
    assign o_stride_index_offset    = stride_idx_offset;
    assign o_stride                 = calcs_stride;
    assign o_group_offset           = group_offset;
    assign o_new_stage_trigger      = new_stage_trigger;
    assign o_sram_read_register     = sram_read_register;
    assign o_valid_data             = valid_data;
    assign o_fft_done               = fft_done_delay[DELAY-1:0];

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

        // case (i_point_configuration)
        //     3'b000: reset_group_offset = 1;
        //     3'b001: reset_group_offset = 3;
        //     3'b010: reset_group_offset = 5;
        //     3'b011: reset_group_offset = 7;
        //     3'b100: reset_group_offset = 9;
        //     3'b101: reset_group_offset = 11;
        //     3'b110: reset_group_offset = 13;
        //     3'b111: reset_group_offset = 15;
        // endcase

        // Algo fix
        case (i_point_configuration)
            3'b000: reset_group_offset = 0;
            3'b001: reset_group_offset = 2;
            3'b010: reset_group_offset = 4;
            3'b011: reset_group_offset = 8;
            3'b100: reset_group_offset = 16;
            3'b101: reset_group_offset = 32;
            3'b110: reset_group_offset = 64;
            3'b111: reset_group_offset = 128;
        endcase
    end

    logic internal_new_stage_trigger;
    assign new_stage_trigger = (counter_delay_reg[DELAY-1] == reset_calcs_stride);
    // This internal new stage trigger happens a cycle earlier than in the external modules
    // This is becuase the updated control signals in this module need to be available
    // when the other modules see the new_stage_trigger, doing the update a cycle early allows
    // this
    assign internal_new_stage_trigger = (counter_delay_reg[DELAY-2] == reset_calcs_stride);

    integer i;

    always_ff @(posedge clk or negedge i_resetn) begin
        // Shift registers
        if(!i_resetn) begin
            calcs_stride          <= reset_calcs_stride; 
            stride_idx_offset     <= reset_stride_idx_offset;
            internal_group_offset <= reset_group_offset;
            group_offset          <= reset_group_offset + 1;
        end else if(internal_new_stage_trigger) begin
            calcs_stride          <= calcs_stride >> 1;
            stride_idx_offset     <= stride_idx_offset >> 1;
            // Algo fix
            internal_group_offset <= internal_group_offset >> 1;
            group_offset          <= (group_offset <= 3) ? 2 : (internal_group_offset >> 1) + 1;
        end else begin
            calcs_stride          <= calcs_stride; 
            stride_idx_offset     <= stride_idx_offset;
            group_offset          <= group_offset;
        end

        if(!i_resetn || fft_done) begin
            valid_data <= 0;
        end else if(i_working) begin
            valid_data <= calc_counter < reset_calcs_stride;
        end else begin
            valid_data <= 0;
        end

        // Calc counter
        if(new_stage_trigger || !i_resetn) begin
            calc_counter <= 0;
        end else if(i_working && !fft_done) begin
            calc_counter <= calc_counter + 4;
        end else begin
            calc_counter <= calc_counter;
        end

        // Output delays
        for(i = 1; i < DELAY; i = i + 1) begin
            if(!i_resetn) begin
                counter_delay_reg[i] <= 0;
                fft_done_delay[i] <= 0;
            end else begin
                counter_delay_reg[i] <= counter_delay_reg[i-1];
                fft_done_delay[i] <= fft_done_delay[i-1];
            end
        end

        if(!i_resetn) begin
            counter_delay_reg[0] <= 0;
            fft_done_delay[0] <= 0;
        end else begin
            counter_delay_reg[0] <= calc_counter;
            fft_done_delay[0] <= fft_done;
        end

        // Control signal outputs
        if(!i_resetn) begin
            sram_read_register <= 0;
        end else if(new_stage_trigger) begin
            sram_read_register <= ~sram_read_register;
        end else begin
            sram_read_register <= sram_read_register;
        end

        if(!i_resetn) begin
            fft_done <= 0;
        end else if(calcs_stride == 1 & new_stage_trigger) begin
            fft_done <= 1;
        end else begin
            fft_done <= fft_done;
        end

        

    end

endmodule