/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn bus master and slave (combined) interface - one cycle read delay.
 *
 */

module rcn_master_slave
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
    output [31:0] rsp_data,

    output slave_cs,
    output slave_wr,
    output [3:0] slave_mask,
    output [23:0] slave_addr,
    output [31:0] slave_wdata,
    input [31:0] slave_rdata
);
    parameter MASTER_ID = 0;
    parameter ADDR_MASK = 0;
    parameter ADDR_BASE = 1;

    reg [68:0] rin;
    reg [68:0] rin_d1;
    reg [68:0] rout;

    assign rcn_out = rout;

    wire [5:0] my_id = MASTER_ID;
    wire [23:0] my_mask = ADDR_MASK;
    wire [23:0] my_base = ADDR_BASE;

    wire my_resp = rin_d1[68] && !rin_d1[67] && (rin_d1[65:60] == my_id);

    wire my_req = rin[68] && rin[67] && ((rin[55:34] & my_mask[23:2]) == my_base[23:2]);
    reg my_req_d1;

    wire [68:0] resp;

    wire req_valid;
    wire [68:0] req;

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            rin <= 69'd0;
            rin_d1 <= 69'd0;
            my_req_d1 <= 1'b0;
            rout <= 69'd0;
        end
        else
        begin
            rin <= rcn_in;
            rin_d1 <= rin;
            my_req_d1 <= my_req;
            rout <= (my_req_d1) ? resp : (req_valid) ? req : (my_resp) ? 69'd0 : rin_d1;
        end

    assign busy = rin_d1[68] && !my_resp;
    assign req_valid = cs && !(rin_d1[68] && !my_resp);
    assign req = {1'b1, 1'b1, wr, my_id, mask, addr[23:2], seq, wdata};

    assign rdone = my_resp && !rin_d1[66];
    assign wdone = my_resp && rin_d1[66];
    assign rsp_seq = rin_d1[33:32];
    assign rsp_mask = rin_d1[59:56];
    assign rsp_addr = {rin_d1[55:34], 2'd0};
    assign rsp_data = rin_d1[31:0];

    assign slave_cs = my_req;
    assign slave_wr = rin[66];
    assign slave_mask = rin[59:56];
    assign slave_addr = {rin[55:34], 2'd0};
    assign slave_wdata = rin[31:0];

    assign resp = {1'b1, 1'b0, rin_d1[66:32], slave_rdata};

endmodule
