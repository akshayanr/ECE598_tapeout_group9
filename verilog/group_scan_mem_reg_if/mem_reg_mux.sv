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
    //output reg [8:0] sram_addr,
    output reg [7:0] sram_addr,
    output reg [127:0] sram_bweb, 
    //output reg [31:0] sram_wdata,
    output reg [127:0] sram_wdata,
    //input [31:0] sram_rdata,
    input [127:0] sram_rdata,
    input sram_ready,

    // cycle configuration control reg
    output reg cycle_cfg_ren,
    output reg cycle_cfg_wen,
    output reg [10:0] cycle_cfg_wdata,
    input [10:0] cycle_cfg_rdata,
    input cycle_cfg_ready,

     // point configuration control reg
    output reg pnt_cfg_ren,
    output reg pnt_cfg_wen,
    output reg [2:0] pnt_cfg_wdata,
    input [2:0] pnt_cfg_rdata,
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
    input fft_done
    //input select_sram_reg

);

    reg [31:0] sram_rdata_trunc;

    always @* begin
        scan_ready <=  sram_ready | pnt_cfg_ready | cycle_cfg_ready | start_fft_ready | reset_fft_ready;
        scan_rdata <=  pnt_cfg_ready ? pnt_cfg_rdata :
                   cycle_cfg_ready ? cycle_cfg_rdata :
                   start_fft_ready ? start_fft_rdata :
                   reset_fft_ready ? reset_fft_rdata :
                    sram_ready ? sram_rdata_trunc   : 
                    scan_addr[10] && scan_addr[6] ? fft_done : 
                    32'h0;
    end

    always @* begin
        sram_wen   = (!scan_addr[10]) ? scan_wen : 0;
        sram_ren   = (!scan_addr[10]) ? scan_ren : 0;

	    pnt_cfg_wen = (scan_addr[10] && scan_addr[9]) ? scan_wen : 0;
	    pnt_cfg_ren = (scan_addr[10] && scan_addr[9]) ? scan_ren : 0;

        cycle_cfg_wen = (scan_addr[10] && scan_addr[5]) ? scan_wen : 0;
	    cycle_cfg_ren = (scan_addr[10] && scan_addr[5]) ? scan_ren : 0;

        start_fft_wen = (scan_addr[10] && scan_addr[8]) ? scan_wen : 0;
        start_fft_ren = (scan_addr[10] && scan_addr[8]) ? scan_ren : 0;

        reset_fft_wen = (scan_addr[10] && scan_addr[7]) ? scan_wen : 0;
        reset_fft_ren = (scan_addr[10] && scan_addr[7]) ? scan_ren : 0;

        //still need to be able to read status registers like done to figure out that it is done.
        //so this is the address that will help us check that.
        //scan_addr[6] will indicate this along with scan_addr[10]
    end

    always @* begin
        //sram_wdata    = !scan_addr[10] ? scan_wdata        : 0;
        //sram_addr     = !scan_addr[10] ? scan_addr[8:0]   : 0;

        //translates to sram index
        sram_addr = (!scan_addr[10]) ? scan_addr[9:2] : 0;

        cycle_cfg_wdata = scan_addr[10] ? scan_wdata[10:0] : 0;

	    pnt_cfg_wdata  = scan_addr[10]  ? scan_wdata[2:0] : 0;

        start_fft_wdata = scan_addr[10] ? scan_wdata[0] : 0;
        reset_fft_wdata = scan_addr[10] ? scan_wdata[0] : 0;

    
        case(scan_addr[1:0])
            2'b00: begin
                sram_rdata_trunc = sram_rdata[31:0];
                sram_wdata = {96'd0, scan_wdata};
                sram_bweb = {32'hffffffff, 32'hffffffff, 32'hffffffff, 32'h00000000};
            end
            2'b01: begin
                sram_rdata_trunc = sram_rdata[63:32];
                sram_wdata = {64'd0, scan_wdata, 32'd0}; 
                sram_bweb = {32'hffffffff, 32'hffffffff, 32'h00000000, 32'hffffffff};
            end
            2'b10: begin
                sram_rdata_trunc = sram_rdata[95:64];
                sram_wdata = {32'd0, scan_wdata, 64'd0}; 
                sram_bweb = {32'hffffffff, 32'h00000000, 32'hffffffff, 32'hffffffff};
            end
            2'b11: begin
                sram_rdata_trunc = sram_rdata[127:96]; 
                sram_wdata = {scan_wdata, 96'd0}; 
                sram_bweb = {32'h00000000, 32'hffffffff, 32'hffffffff, 32'hffffffff};
            end
            default: begin
                sram_rdata_trunc = sram_rdata[127:96]; 
                sram_wdata = {scan_wdata, 96'd0}; 
                sram_bweb = 128'h0;
            end
        endcase

    end

endmodule
