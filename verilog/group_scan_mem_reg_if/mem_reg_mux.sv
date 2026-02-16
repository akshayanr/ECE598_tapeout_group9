// Mem and reg mux
// This module selects the interface between the SRAM and the control registers.
// If the MSB of scan_addr is 0, the SRAM is selected; if it is 1, the control registers are selected.

module mem_reg_mux (
    // to scan_syn_ctr
    input  scan_ren,
    input  scan_wen,
    input  [10:0] scan_addr,
    input  [31:0] scan_wdata,
    output reg [31:0] scan_rdata,  
    output reg scan_ready,

    // to sram
    output reg sram_ren,
    output reg sram_wen,
    output reg [8:0] sram_addr,
    output reg [31:0] sram_wdata,
    input [31:0] sram_rdata,
    input sram_ready,

    // point configuration control reg
    output reg pnt_cfg_ren,
    output reg pnt_cfg_wen,
    output reg [2:0] pnt_cfg_wdata,
    input [10:0] pnt_cfg_rdata,
    input pnt_cfg_ready,

    // start fft control reg
    output reg start_fft_ren,
    output reg start_fft_wen,
    output reg start_fft_wdata,
    input start_fft_rdata,
    input start_fft_ready,

    // reset fft control reg
    output reg reset_fft_ren,
    output reg reset_fft_wen,
    output reg reset_fft_wdata,
    input reset_fft_rdata,
    input reset_fft_ready,

    // done status reg
    input fft_done,
    input select_sram_reg

);

    always @* begin
        scan_ready <=  sram_ready | pnt_cfg_ready | start_fft_ready | reset_fft_ready;
        scan_rdata <=  pnt_cfg_ready ? pnt_cfg_rdata :
                   start_fft_ready ? start_fft_wdata :
                   reset_fft_ready ? reset_fft_wdata :
                     sram_ready ? sram_rdata   : 32'h0;
    end

    always @* begin
        sram_wen   = !scan_addr[10] ? scan_wen : 0;
        sram_ren   = !scan_addr[10] ? scan_ren : 0;

	    pnt_cfg_wen = scan_addr[10] && scan_addr[9] ? scan_wen : 0;
	    pnt_cfg_ren = scan_addr[10] && scan_addr[9] ? scan_ren : 0;

        start_fft_wen = scan_addr[10] && scan_addr[8] ? scan_wen : 0;
        start_fft_ren = scan_addr[10] && scan_addr[8] ? scan_ren : 0;

        reset_fft_wen = scan_addr[10] && scan_addr[7] ? scan_wen : 0;
        reset_fft_ren = scan_addr[10] && scan_addr[7] ? scan_ren : 0;
    end

    always @* begin
        sram_wdata    = !scan_addr[10] ? scan_wdata        : 0;
        sram_addr     = !scan_addr[10] ? scan_addr[8:0]   : 0;

	    pnt_cfg_wdata  = scan_addr[10]  ? scan_wdata[2:0] : 0;

        start_fft_wdata = scan_addr[10] ? scan_wdata[0] : 0;
        reset_fft_wdata = scan_addr[10] ? scan_wdata[0] : 0;

    end

endmodule
