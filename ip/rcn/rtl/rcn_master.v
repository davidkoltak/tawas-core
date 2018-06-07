/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn bus master interface.
 *
 * rcn bus vector definition =
 *   {valid, pending, wr, id[5:0], mask[3:0], addr[23:2], seq[1:0], data[31:0]}
 *
 *  data    = [31:0]
 *  seq     = [33:32]
 *  addr    = [55:34]
 *  mask    = [59:56]
 *  id      = [65:60]
 *  wr      = [66]
 *  pending = [67]
 *  valid   = [68]
 *
 */

module rcn_master
(
    input rst,
    input clk,

    input [68:0] rcn_in,
    output [68:0] rcn_out,

    input cs,
    input [1:0] seq,
    output busy,
    input wr,
    input [3:0] mask,
    input [23:0] addr,
    input [31:0] wdata,

    output rdone,
    output wdone,
    output [1:0] rsp_seq,
    output [3:0] rsp_mask,
    output [23:0] rsp_addr,
    output [31:0] rsp_data
);
    parameter MASTER_ID = 0;

    reg [68:0] rin;
    reg [68:0] rout;

    assign rcn_out = rout;

    wire [5:0] my_id = MASTER_ID;

    wire my_resp = rin[68] && !rin[67] && (rin[65:60] == my_id);

    wire my_req_valid;
    wire [68:0] my_req;

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            rin <= 69'd0;
            rout <= 69'd0;
        end
        else
        begin
            rin <= rcn_in;
            rout <= (my_req_valid) ? my_req : (my_resp) ? 69'd0 : rin;
        end

    assign busy = rin[68] && !my_resp;
    assign my_req_valid = cs && !(rin[68] && !my_resp);
    assign my_req = {1'b1, 1'b1, wr, my_id, mask, addr[23:2], seq, wdata};

    assign rdone = my_resp && !rin[66];
    assign wdone = my_resp && rin[66];
    assign rsp_seq = rin[33:32];
    assign rsp_mask = rin[59:56];
    assign rsp_addr = {rin[55:34], 2'd0};
    assign rsp_data = rin[31:0];

endmodule
