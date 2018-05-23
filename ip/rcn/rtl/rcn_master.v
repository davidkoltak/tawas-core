/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn bus master interface.
 *
 * rcn bus vector definition =
 *   {valid, pending, wr, id[5:0], seq[1:0], we[3:0], addr[21:2], data[31:0]}
 */

module rcn_master
(
    input rst,
    input clk,
    
    input [66:0] rcn_in,
    output [66:0] rcn_out,
    
    input cs,
    input [1:0] seq,
    output busy,
    input wr,
    input [3:0] mask,
    input [21:0] addr,
    input [31:0] wdata,
    
    output rdone,
    output wdone,
    output [1:0] rsp_seq,
    output [3:0] rsp_mask,
    output [21:0] rsp_addr,
    output [31:0] rsp_data
);
    parameter MASTER_ID = 0;
    
    reg [66:0] rin;
    reg [66:0] rout;
    
    assign rcn_out = rout;

    wire [5:0] my_id = MASTER_ID;
    
    wire my_resp = rin[66] && !rin[65] && (rin[63:58] == my_id);
    
    wire my_req_valid;
    wire [66:0] my_req;
    
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            rin <= 67'd0;
            rout <= 67'd0;
        end
        else
        begin
            rin <= rcn_in;
            rout <= (my_req_valid) ? my_req : (my_resp) ? 67'd0 : rin;
        end
    
    assign busy = cs && rin[66] && !my_resp;
    assign my_req_valid = cs && (!rin[66] || my_resp);
    assign my_req = {1'b1, 1'b1, wr, my_id, seq, mask, addr[21:2], wdata};
    
    assign rdone = my_resp && !rin[64];
    assign wdone = my_resp && rin[64];
    assign rsp_seq = rin[57:56];
    assign rsp_addr = {rin[51:32], 2'd0};
    assign rsp_data = rin[31:0];
    
endmodule
