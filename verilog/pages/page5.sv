module page5(
    input [31:0] i_read_output1, 
    input [31:0] i_butterfly1_bottom, 
    input [31:0] i_twidle_factor1,

    input [31:0] i_butterfly2_top, 
    input [31:0] i_butterfly2_bottom, 
    input [31:0] i_twidle_factor2, 

    input [31:0] i_butterfly3_top, 
    input [31:0] i_butterfly3_bottom, 
    input [31:0] i_twidle_factor3, 

    input [31:0] i_butterfly4_top, 
    input [31:0] i_butterfly4_bottom, 
    input [31:0] i_twidle_factor4, 

    input clock,

    output [127:0] o_write_val1, 
    output [127:0] o_write_val2  
);


    //butterfly currently doesn't do multiplcation

endmodule