/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn bus bridge.
 *
 * rcn bus vector definition =
 *   {valid, pending, wr, id[5:0], seq[1:0], mask[3:0], addr[19:0], data[31:0]}
 */

module rcn_bridge
(
    input rst,
    input clk,
    
    input [66:0] main_rcn_in,
    output [66:0] main_rcn_out,

    input [66:0] sub_rcn_in,
    output [66:0] sub_rcn_out
);
    parameter ID_MASK = 0;
    parameter ID_BASE = 0;
    parameter ADDR_MASK = 0;
    parameter ADDR_BASE = 0;
    
    reg [66:0] main_rin;
    reg [66:0] main_rout;
    reg [66:0] sub_rin;
    reg [66:0] sub_rout;
    
    assign main_rcn_out = main_rout;
    assign sub_rcn_out = sub_rout;

    wire [5:0] my_id_mask = ID_MASK;
    wire [5:0] my_id_base = ID_BASE;
    wire [31:0] my_addr_mask = ADDR_MASK;
    wire [31:0] my_addr_base = ADDR_BASE;
    
    wire main_req = main_rin[66] && main_rin[65];
    wire main_rsp = main_rin[66] && !main_rin[65];
    wire main_id_match = ((main_rin[63:58] & my_id_mask) == my_id_base);
    wire main_addr_match = ((main_rin[51:32] & my_addr_mask[21:2]) == my_addr_base[21:2]);
    
    wire sub_req = sub_rin[66] && sub_rin[65];
    wire sub_rsp = sub_rin[66] && !sub_rin[65];
    wire sub_id_match = ((sub_rin[63:58] & my_id_mask) == my_id_base);
    wire sub_addr_match = ((sub_rin[51:32] & my_addr_mask[21:2]) == my_addr_base[21:2]);
    
    wire main_2_main = (main_req && !main_addr_match) || (main_rsp && !main_id_match);
    wire sub_2_sub = (sub_req && sub_addr_match) || (sub_rsp && sub_id_match);
    wire no_cross = main_2_main || sub_2_sub;
    
    wire main_2_sub = (main_req && main_addr_match) || (main_rsp && main_id_match);
    wire sub_2_main = (sub_req && !sub_addr_match) || (sub_rsp && !sub_id_match);
    
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            main_rin <= 67'd0;
            main_rout <= 67'd0;
            sub_rin <= 67'd0;
            sub_rout <= 67'd0;
        end
        else
        begin
            main_rin <= main_rcn_in;
            main_rout <= (sub_2_main && !no_cross) ? sub_rin : main_rin;
            
            sub_rin <= sub_rcn_in;
            sub_rout <= (main_2_sub && !no_cross) ? main_rin : sub_rin;
        end
        
endmodule
