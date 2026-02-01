module butterfly (
    input i_clk,

    input [31:0] i_a,
    input [31:0] i_b,
    output logic [31:0] o_a,
    output logic [31:0] o_b
);

// o_a = i_a + i_b
// o_b = i_a - i_b
logic [31:0] input_a, input_b;
wire [31:0] output_a, output_b;

wire [15:0] real_a_in, imag_a_in, real_b_in, imag_b_in;
wire [15:0] real_a_out, imag_a_out, real_b_out, imag_b_out;

assign real_a_in = input_a[31:16];
assign imag_a_in = input_a[15:0];

assign real_b_in = input_b[31:16];
assign imag_b_in = input_b[15:0];

assign output_a = {real_a_out, imag_a_out};
assign output_b = {real_b_out, imag_b_out};

// Rounding config for adders/subtractors
wire [2:0] rnd [0:3];
assign rnd[0] = 3'b000; //Round to nearest even
assign rnd[1] = 3'b000;
assign rnd[2] = 3'b000;
assign rnd[3] = 3'b000;

// Status output for adders/subtractors
logic [7:0] status [0:3];

always_ff @(posedge i_clk) begin
    input_a <= i_a;
    input_b <= i_b;
    o_a <= output_a;
    o_b <= output_b;
end

// Instance of DW_fp_add for computing real part of a
DW_fp_add #(.sig_width(10), .exp_width(5), .ieee_compliance(3))
real_a_add ( .a(real_a_in), .b(real_b_in), .rnd(rnd[0]), .z(real_a_out), .status(status[0]));

// Instance of DW_fp_add for computing imag part of a
DW_fp_add #(.sig_width(10), .exp_width(5), .ieee_compliance(3))
imag_a_add ( .a(imag_a_in), .b(imag_b_in), .rnd(rnd[1]), .z(imag_a_out), .status(status[1]));

// Instance of DW_fp_sub for computing real part of b
DW_fp_sub #(.sig_width(10), .exp_width(5), .ieee_compliance(3))
real_b_sub ( .a(real_a_in), .b(real_b_in), .rnd(rnd[2]), .z(real_b_out), .status(status[2]));

// Instance of DW_fp_sub for computing imag part of b
DW_fp_sub #(.sig_width(10), .exp_width(5), .ieee_compliance(3))
imag_b_sub ( .a(imag_a_in), .b(imag_b_in), .rnd(rnd[3]), .z(imag_b_out), .status(status[3]));


endmodule