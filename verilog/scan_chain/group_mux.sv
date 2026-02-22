module group_mux(
    // Inputs & outputs to the block_scan.sv
    scan_id,
    static_wen,
    static_ren,
    static_addr,
    static_wdata,
    static_rdata,
    static_ready,

    // Inputs & outputs to the first group
    static_wen_A,
    static_ren_A,
    static_addr_A,
    static_wdata_A,
    static_rdata_A,
    static_ready_A,
    scan_id_A,

    // Inputs & outputs to the second group
    static_wen_B,
    static_ren_B,
    static_addr_B,
    static_wdata_B,
    static_rdata_B,
    static_ready_B,
    scan_id_B,

    // Inputs & outputs to the third group
    static_wen_C,
    static_ren_C,
    static_addr_C,
    static_wdata_C,
    static_rdata_C,
    static_ready_C,
    scan_id_C   
);

input   [1-1:0]  scan_id;
input   [1-1:0]  static_wen;
input   [1-1:0]  static_ren;
input   [20-1:0] static_addr;
input   [32-1:0] static_wdata;
output  [32-1:0] static_rdata;
output  [1-1:0]  static_ready;

output  [1-1:0]  scan_id_A;
output  [1-1:0]  static_wen_A;
output  [1-1:0]  static_ren_A;
output  [20-1:0] static_addr_A;
output  [32-1:0] static_wdata_A;
input   [32-1:0] static_rdata_A;
input   [1-1:0]  static_ready_A;

output  [1-1:0]  scan_id_B;
output  [1-1:0]  static_wen_B;
output  [1-1:0]  static_ren_B;
output  [20-1:0] static_addr_B;
output  [32-1:0] static_wdata_B;
input   [32-1:0] static_rdata_B;
input   [1-1:0]  static_ready_B;

output  [1-1:0]  scan_id_C;
output  [1-1:0]  static_wen_C;
output  [1-1:0]  static_ren_C;
output  [20-1:0] static_addr_C;
output  [32-1:0] static_wdata_C;
input   [32-1:0] static_rdata_C;
input   [1-1:0]  static_ready_C;

reg scan_id_A;
reg scan_id_B;
reg scan_id_C;
wire Group_ID;

// 00 -> group A
// 01 -> group B
// 10 -> group C
assign Group_ID = static_addr[19:18];
wire sel_A = (Group_ID == 2'b00);
wire sel_B = (Group_ID == 2'b01);
wire sel_C = (Group_ID == 2'b10);


assign scan_id_A       = sel_A ? scan_id       : scan_id_A;
assign static_wen_A    = sel_A ? static_wen    : 1'b0;
assign static_ren_A    = sel_A ? static_ren    : 1'b0;
assign static_addr_A   = sel_A ? static_addr   : 20'b0;
assign static_wdata_A  = sel_A ? static_wdata  : 32'b0;

assign scan_id_B       = sel_B ? scan_id       : scan_id_B;
assign static_wen_B    = sel_B ? static_wen    : 1'b0;
assign static_ren_B    = sel_B ? static_ren    : 1'b0;
assign static_addr_B   = sel_B ? static_addr   : 20'b0;
assign static_wdata_B  = sel_B ? static_wdata  : 32'b0;

assign scan_id_C       = sel_C ? scan_id       : scan_id_C;
assign static_wen_C    = sel_C ? static_wen    : 1'b0;
assign static_ren_C    = sel_C ? static_ren    : 1'b0;
assign static_addr_C   = sel_C ? static_addr   : 20'b0;
assign static_wdata_C  = sel_C ? static_wdata  : 32'b0;

// 
assign static_rdata =
      sel_A ? static_rdata_A :
      sel_B ? static_rdata_B :
      sel_C ? static_rdata_C :
              32'b0;

assign static_ready =
      sel_A ? static_ready_A :
      sel_B ? static_ready_B :
      sel_C ? static_ready_C :
              1'b0;
endmodule