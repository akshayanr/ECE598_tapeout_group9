module block_scan (
    // Inputs & outputs to the chip
    static_wen,
    static_ren,
    static_addr,
    static_wdata,
    static_rdata,
    static_ready,

    // To the pads
    scan_phi,
    scan_phi_bar,
    scan_data_in,
    scan_data_out,
    scan_load_chip,
    scan_load_chain
);

// Ports
input  scan_phi;
input  scan_phi_bar;
input  scan_data_in;
output scan_data_out;
input  scan_load_chain;
input  scan_load_chip;

output reg [1-1:0] static_wen;
output reg [1-1:0] static_ren;
output reg [20-1:0] static_addr;
output reg [32-1:0] static_wdata;
input [32-1:0] static_rdata;
input [1-1:0]  static_ready;

// Implementation

// The scan chain is comprised of two sets of latches: scan_master and scan_slave.

reg  [86:0] scan_master;
reg  [86:0] scan_slave;

reg  [86:0] scan_load;
wire [86:0] scan_next;

always @* begin
    scan_load[0:0] = static_wen;
    scan_load[1:1] = static_ren;
    scan_load[21:2]  = static_addr;
    scan_load[53:22] = static_wdata; 
    scan_load[85:54] = static_rdata;
    scan_load[86:86] = static_ready;
end

assign scan_next = scan_load_chain ? scan_load : {scan_data_in, scan_slave[86:1]};

// synopsys one_hot "scan_phi, scan_phi_bar"
always @* begin
    if (scan_phi)
        scan_master = scan_next;
    if (scan_phi_bar)
        scan_slave = scan_master;
end

// static_xx refers to the Data lacthes in the slides
// (M + 1) bits have been removed for read operation, where M = 32
always @* if (scan_load_chip) begin
    static_wen   = scan_slave[0];
    static_ren   = scan_slave[1];
    static_addr  = scan_slave[21:2];
    static_wdata = scan_slave[53:22];
end

assign scan_data_out = scan_slave[0];

endmodule
