module full_butterfly #(
    parameter BUTTERFLY_STAGES = 2,
    parameter MULT_STAGES = 3
)(
    input clk,
    input [31:0] i_butterfly_top,
    input [31:0] i_butterfly_bot,
    input [8:0] i_twiddle_addr,
    input i_valid,

    output [31:0] o_butterfly_top,
    output [31:0] o_butterfly_bot
);


    // Need twiddle arrival to match butterfly, and 
    // top butterfly needs to match multiplier
    logic [31:0] butterfly_top_out;
    logic [31:0] butterfly_bot_out;
    logic [31:0] butterfly_top_delay [MULT_STAGES-1:0];

    logic [8:0] twiddle_addr;
    logic [31:0] twiddle_data;

    logic valid_data;

    assign o_butterfly_top = butterfly_top_delay[MULT_STAGES-1];

    butterfly addsub ( 
        .i_clk(clk), 
        .i_a(i_butterfly_top), 
        .i_b(i_butterfly_bot), 
        .o_a(butterfly_top_out), 
        .o_b(butterfly_bot_out)
    );

    mult multiplier (
        .i_clk(clk),

        .i_mcand(butterfly_bot_out),
        .i_mplier(twiddle_data),
        .o_result(o_butterfly_bot)
    );

    rom twiddle_rom (
        .clk(clk),
        .i_addr(twiddle_addr),
        .i_ce_b(!valid_data),
        .o_rdata(twiddle_data)
    );

    integer i;
    always_ff @(posedge clk) begin
        for(i = 1; i < MULT_STAGES; i = i +1) begin
            butterfly_top_delay[i] <= butterfly_top_delay[i - 1];
        end
            butterfly_top_delay[0] <= butterfly_top_out;

        twiddle_addr  <= i_twiddle_addr;
        valid_data <= i_valid;
    end


endmodule