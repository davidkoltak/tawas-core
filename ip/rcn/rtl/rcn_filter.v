/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Bus address filter - squash any cycle within ranges
//

module rcn_filter
(
    input clk,
    input rst,

    input [68:0] rcn_in,
    output [68:0] rcn_out,
    
    output reg filtered
);
    parameter START_0 = 1;
    parameter END_0 = 0;
    parameter START_1 = 1;
    parameter END_1 = 0;
    parameter START_2 = 1;
    parameter END_2 = 0;
    parameter START_3 = 1;
    parameter END_3 = 0;

    reg [68:0] rin;
    reg [68:0] rout;
    
    assign rcn_out = rout;
    
    wire [23:0] addr_start_0 = START_0;
    wire [23:0] addr_end_0 = END_0;
    wire filter_0 = (rin[55:34] >= addr_start_0) && (rin[55:34] <= addr_end_0);
    
    wire [23:0] addr_start_1 = START_1;
    wire [23:0] addr_end_1 = END_1;
    wire filter_1 = (rin[55:34] >= addr_start_1) && (rin[55:34] <= addr_end_1);
    
    wire [23:0] addr_start_2 = START_2;
    wire [23:0] addr_end_2 = END_2;
    wire filter_2 = (rin[55:34] >= addr_start_2) && (rin[55:34] <= addr_end_2);
    
    wire [23:0] addr_start_3 = START_3;
    wire [23:0] addr_end_3 = END_3;
    wire filter_3 = (rin[55:34] >= addr_start_3) && (rin[55:34] <= addr_end_3);
    
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            rin <= 69'd0;
            rout <= 69'd0;
            filtered <= 1'b0;
        end
        else
        begin
            rin <= rcn_in;
            rout <= (filter_0 || filter_1 || filter_2 || filter_3) ? 69'd0 : rcn_in;
            filtered <= (filter_0 || filter_1 || filter_2 || filter_3);
        end
    

endmodule
