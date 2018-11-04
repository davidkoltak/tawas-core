/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn bus master interface for tawas core.
 * Uses 8 master ids x 4 sequence ids to map to 32-threads.
 *
 */

module tawas_rcn_master
(
    input rst,
    input clk,

    input [68:0] rcn_in,
    output [68:0] rcn_out,

    input cs,
    input [4:0] seq,
    output busy,
    input wr,
    input [3:0] mask,
    input [23:0] addr,
    input [31:0] wdata,

    output rdone,
    output wdone,
    output [4:0] rsp_seq,
    output [3:0] rsp_mask,
    output [23:0] rsp_addr,
    output [31:0] rsp_data
);
    parameter MASTER_GROUP_8 = 0;
    
    reg [68:0] rin;
    reg [68:0] rout;

    assign rcn_out = rout;

    wire [2:0] my_id = MASTER_GROUP_8;

    wire my_resp = rin[68] && !rin[67] && (rin[65:63] == MASTER_GROUP_8);

    wire req_valid;
    wire [68:0] req;

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            rin <= 69'd0;
            rout <= 69'd0;
        end
        else
        begin
            rin <= rcn_in;
            rout <= (req_valid) ? req : (my_resp) ? 69'd0 : rin;
        end

    assign busy = rin[68] && !my_resp;
    assign req_valid = cs && !(rin[68] && !my_resp);
    assign req = {1'b1, 1'b1, wr, my_id, seq[4:2], mask, addr[23:2], seq[1:0], wdata};

    assign rdone = my_resp && !rin[66];
    assign wdone = my_resp && rin[66];
    assign rsp_seq = {rin[62:60], rin[33:32]};
    assign rsp_mask = rin[59:56];
    assign rsp_addr = {rin[55:34], 2'd0};
    assign rsp_data = rin[31:0];

endmodule
