module mem_interface (
    input  [7:0]   raddress1,
    output [127:0] rdata1,
    input  [7:0]   raddress2,
    output [127:0] rdata2,
    input  [7:0]   waddress1,
    input  [127:0] wdata1,
    input  [7:0]   waddress2,
    input  [127:0] wdata2,
    input          sram_read_register,
      
    // SRAM0 Ports
    output SRAM0_BIST0, SRAM0_AWT0,
    output SRAM0_CEBA0, SRAM0_CEBB0, 
    output SRAM0_WEBA0, SRAM0_WEBB0,
    output [7:0] SRAM0_AA0, SRAM0_AB0,
    output [63:0] SRAM0_DA0, SRAM0_DB0,
    output [63:0] SRAM0_BWEBA0, SRAM0_BWEBB0,
    input  [63:0] SRAM0_QA0, SRAM0_QB0,

    output SRAM0_BIST1, SRAM0_AWT1,
    output SRAM0_CEBA1, SRAM0_CEBB1, 
    output SRAM0_WEBA1, SRAM0_WEBB1,
    output [7:0] SRAM0_AA1, SRAM0_AB1,
    output [63:0] SRAM0_DA1, SRAM0_DB1,
    output [63:0] SRAM0_BWEBA1, SRAM0_BWEBB1,
    input  [63:0] SRAM0_QA1, SRAM0_QB1,

    // SRAM1 Ports
    output SRAM1_BIST0, SRAM1_AWT0,
    output SRAM1_CEBA0, SRAM1_CEBB0, 
    output SRAM1_WEBA0, SRAM1_WEBB0,
    output [7:0] SRAM1_AA0, SRAM1_AB0,
    output [63:0] SRAM1_DA0, SRAM1_DB0,
    output [63:0] SRAM1_BWEBA0, SRAM1_BWEBB0,
    input  [63:0] SRAM1_QA0, SRAM1_QB0,

    output SRAM1_BIST1, SRAM1_AWT1,
    output SRAM1_CEBA1, SRAM1_CEBB1, 
    output SRAM1_WEBA1, SRAM1_WEBB1,
    output [7:0] SRAM1_AA1, SRAM1_AB1,
    output [63:0] SRAM1_DA1, SRAM1_DB1,
    output [63:0] SRAM1_BWEBA1, SRAM1_BWEBB1,
    input  [63:0] SRAM1_QA1, SRAM1_QB1
); 

logic [63:0] rdata1h, rdata1l, rdata2h, rdata2l;
logic [63:0] wdata1h, wdata1l, wdata2h, wdata2l;

// ==========================================
// SRAM 0 LOGIC (Lower 64 & Upper 64 bits)
// ==========================================
assign SRAM0_BIST0 = 0; assign SRAM0_AWT0 = 0;
assign SRAM0_BIST1 = 0; assign SRAM0_AWT1 = 0;

// Both chip enables tied low (always active) to allow simultaneous read/write
assign SRAM0_CEBA0 = 1'b0; assign SRAM0_CEBB0 = 1'b0;
assign SRAM0_CEBA1 = 1'b0; assign SRAM0_CEBB1 = 1'b0;

// sram_read_register == 0: WE is 1 (Read Mode). sram_read_register == 1: WE is 0 (Write Mode).
assign SRAM0_WEBA0 = ~sram_read_register; assign SRAM0_WEBB0 = ~sram_read_register;
assign SRAM0_WEBA1 = ~sram_read_register; assign SRAM0_WEBB1 = ~sram_read_register;

// sram_read_register == 0: gets raddress. sram_read_register == 1: gets waddress.
assign SRAM0_AA0 = sram_read_register ? waddress1 : raddress1;
assign SRAM0_AB0 = sram_read_register ? waddress2 : raddress2;
assign SRAM0_AA1 = sram_read_register ? waddress1 : raddress1;
assign SRAM0_AB1 = sram_read_register ? waddress2 : raddress2;

assign SRAM0_DA0 = wdata1l; assign SRAM0_DB0 = wdata2l;
assign SRAM0_DA1 = wdata1h; assign SRAM0_DB1 = wdata2h;

assign SRAM0_BWEBA0 = '0; assign SRAM0_BWEBB0 = '0;
assign SRAM0_BWEBA1 = '0; assign SRAM0_BWEBB1 = '0;


// ==========================================
// SRAM 1 LOGIC (Lower 64 & Upper 64 bits)
// ==========================================
assign SRAM1_BIST0 = 0; assign SRAM1_AWT0 = 0;
assign SRAM1_BIST1 = 0; assign SRAM1_AWT1 = 0;

// Both chip enables tied low (always active)
assign SRAM1_CEBA0 = 1'b0; assign SRAM1_CEBB0 = 1'b0;
assign SRAM1_CEBA1 = 1'b0; assign SRAM1_CEBB1 = 1'b0;

// sram_read_register == 0: WE is 0 (Write Mode). sram_read_register == 1: WE is 1 (Read Mode).
assign SRAM1_WEBA0 = sram_read_register; assign SRAM1_WEBB0 = sram_read_register;
assign SRAM1_WEBA1 = sram_read_register; assign SRAM1_WEBB1 = sram_read_register;

// sram_read_register == 0: gets waddress. sram_read_register == 1: gets raddress.
assign SRAM1_AA0 = sram_read_register ? raddress1 : waddress1;
assign SRAM1_AB0 = sram_read_register ? raddress2 : waddress2;
assign SRAM1_AA1 = sram_read_register ? raddress1 : waddress1;
assign SRAM1_AB1 = sram_read_register ? raddress2 : waddress2;

assign SRAM1_DA0 = wdata1l; assign SRAM1_DB0 = wdata2l;
assign SRAM1_DA1 = wdata1h; assign SRAM1_DB1 = wdata2h;

assign SRAM1_BWEBA0 = '0; assign SRAM1_BWEBB0 = '0;
assign SRAM1_BWEBA1 = '0; assign SRAM1_BWEBB1 = '0;


// ==========================================
// READ DATA MULTIPLEXING (Fixing multiple drivers)
// ==========================================
// If sram_read_register == 0, route SRAM0 data to output. If 1, route SRAM1 data.
assign rdata1l = sram_read_register ? SRAM1_QA0 : SRAM0_QA0;
assign rdata2l = sram_read_register ? SRAM1_QB0 : SRAM0_QB0;
assign rdata1h = sram_read_register ? SRAM1_QA1 : SRAM0_QA1;
assign rdata2h = sram_read_register ? SRAM1_QB1 : SRAM0_QB1;


// ==========================================
// WRITE DATA SPLITTING & READ DATA CONCATENATION
// ==========================================
assign wdata1h = wdata1[127:64];
assign wdata1l = wdata1[63:0];
assign rdata1  = {rdata1h, rdata1l};

assign wdata2h = wdata2[127:64];
assign wdata2l = wdata2[63:0];
assign rdata2  = {rdata2h, rdata2l};

endmodule