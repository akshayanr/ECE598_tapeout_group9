module mult (
    input i_clk,

    input [31:0] i_mcand,
    input [31:0] i_mplier,
    output logic [31:0] o_result
);


// (a + bi)(c + di)
// real = ac - bd
// imag = ad + bc

// First stage: multiplication
// Second stage: add/sub
logic [31:0] input_mcand, input_mplier;
wire [31:0] result;

wire [15:0] a, b, c, d;
wire [15:0] ac, bd, ad, bc;
logic [15:0] sub_ac, sub_bd, add_ad, add_bc;
wire [15:0] real_out, imag_out;

assign a = input_mcand[31:16];
assign b = input_mcand[15:0];

assign c = input_mplier[31:16];
assign d = input_mplier[15:0];

assign result = {real_out, imag_out};

// Status output for adders/subtractors
logic [7:0] mult_status [0:3];
logic [7:0] sub_status;
logic [7:0] add_status;

always_ff @(posedge i_clk) begin
    input_mcand  <= i_mcand;
    input_mplier <= i_mplier;
    sub_ac <= ac;
    sub_bd <= bd;
    add_ad <= ad;
    add_bc <= bc;
    o_result <= result;
end

// DW config
parameter SIG_WIDTH = 10;
parameter EXP_WIDTH = 5;
parameter IEEE = 3;
parameter EN_UBR = 0;
parameter RND = 3'b000; //Round to nearest even

// 4 Mults
DW_fp_mult #(.sig_width(SIG_WIDTH), .exp_width(EXP_WIDTH), .ieee_compliance(IEEE), .en_ubr_flag(EN_UBR))
mult_ac ( .a(a), .b(c), .rnd(RND), .z(ac), .status(mult_status[0]));

DW_fp_mult #(.sig_width(SIG_WIDTH), .exp_width(EXP_WIDTH), .ieee_compliance(IEEE), .en_ubr_flag(EN_UBR))
mult_bd ( .a(b), .b(d), .rnd(RND), .z(bd), .status(mult_status[1]));

DW_fp_mult #(.sig_width(SIG_WIDTH), .exp_width(EXP_WIDTH), .ieee_compliance(IEEE), .en_ubr_flag(EN_UBR))
mult_ad ( .a(a), .b(d), .rnd(RND), .z(ad), .status(mult_status[2]));

DW_fp_mult #(.sig_width(SIG_WIDTH), .exp_width(EXP_WIDTH), .ieee_compliance(IEEE), .en_ubr_flag(EN_UBR))
mult_bc ( .a(b), .b(c), .rnd(RND), .z(bc), .status(mult_status[3]));

// 2 Add/Sub
DW_fp_sub #(.sig_width(SIG_WIDTH), .exp_width(EXP_WIDTH), .ieee_compliance(IEEE))
real_ac_sub_bd ( .a(sub_ac), .b(sub_bd), .rnd(RND), .z(real_out), .status(sub_status));

DW_fp_add #(.sig_width(SIG_WIDTH), .exp_width(EXP_WIDTH), .ieee_compliance(IEEE))
imag_ad_add_bc ( .a(add_ad), .b(add_bc), .rnd(RND), .z(imag_out), .status(add_status));

endmodule