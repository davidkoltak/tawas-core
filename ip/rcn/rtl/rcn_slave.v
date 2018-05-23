/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn bus slave interface.
 *
 * rcn bus vector definition =
 *   {valid, pending, wr, id[5:0], seq[1:0], we[3:0], addr[21:2], data[31:0]}
 */

module rcn_slave
(
    input rst,
    input clk,
    
    input [66:0] rcn_in,
    output [66:0] rcn_out,
    
    output cs,
    output wr,
    output [3:0] mask,
    output [21:0] addr,
    output [31:0] wdata,
    input [31:0] rdata
);
    parameter ADDR_MASK = 0;
    parameter ADDR_BASE = 0;
    
    reg [66:0] rin;
    reg [66:0] rin_d1;
    reg [66:0] rout;
    
    assign rcn_out = rout;

    wire [31:0] my_mask = ADDR_MASK;
    wire [31:0] my_base = ADDR_BASE;
    
    wire my_req = rin[66] && rin[65] && ((rin[51:32] & my_mask[21:2]) == my_base[21:2]);
    reg my_req_d1;
    
    wire [66:0] my_resp;
    
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            rin <= 67'd0;
            rin_d1 <= 67'd0;
            my_req_d1 <= 1'b0;
            rout <= 67'd0;
        end
        else
        begin
            rin <= rcn_in;
            rin_d1 <= rin;
            my_req_d1 <= my_req;
            rout <= (my_req_d1) ? my_resp : rin_d1;
        end

    assign cs = my_req;
    assign wr = rin[64];
    assign mask = rin[55:52];
    assign addr = {rin[51:32], 2'd0};
    assign wdata = rin[31:0];
    
    assign my_resp = {1'b1, 1'b0, rin_d1[64:32], rdata};
 
endmodule
