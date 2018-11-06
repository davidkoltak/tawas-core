/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * avalon to rcn bus master interface.
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

module avalon2rcn
(
    input av_clk,
    input av_rst,

    output av_waitrequest,
    input [21:0] av_address,
    input av_write,
    input av_read,
    input [3:0] av_byteenable, 
    input [31:0] av_writedata,
    output [31:0] av_readdata,
    output av_readdatavalid,

    input [68:0] rcn_in,
    output [68:0] rcn_out
);
    parameter MASTER_ID = 6'h3F;

    reg [68:0] rin;
    reg [68:0] rout;
    reg [2:0] next_rd_id;
    reg [2:0] wait_rd_id;
    reg [2:0] next_wr_id;
    reg [2:0] wait_wr_id;

    assign rcn_out = rout;

    wire [5:0] my_id = MASTER_ID;

    wire my_resp = rin[68] && !rin[67] && (rin[65:60] == my_id) && 
                   ((rin[66]) ? (rin[33:32] == wait_wr_id[1:0]) : (rin[33:32] == wait_rd_id[1:0]));

    wire bus_stall = (rin[68] && !my_resp) || (av_read) ? (next_rd_id == wait_rd_id) : (next_wr_id == wait_wr_id);
    assign av_waitrequest = bus_stall;

    wire req_valid;
    wire [68:0] req;

    always @ (posedge av_clk or posedge av_rst)
        if (av_rst)
        begin
            rin <= 69'd0;
            rout <= 69'd0;
            next_rd_id <= 3'b000;
            wait_rd_id <= 3'b100;
            next_wr_id <= 3'b000;
            wait_wr_id <= 3'b100;
        end
        else
        begin
            rin <= rcn_in;
            rout <= (req_valid) ? req : (my_resp) ? 69'd0 : rin;
            next_rd_id <= (req_valid && av_read) ? next_rd_id + 3'd1 : next_rd_id;
            wait_rd_id <= (my_resp && !rin[66]) ? wait_rd_id + 3'd1 : wait_rd_id;
            next_wr_id <= (req_valid && av_write) ? next_wr_id + 3'd1 : next_wr_id;
            wait_wr_id <= (my_resp && rin[66]) ? wait_wr_id + 3'd1 : wait_wr_id;
        end

    assign req_valid = (av_write || av_read) && !bus_stall;

    wire [1:0] seq = (av_read) ? next_rd_id[1:0] : next_wr_id[1:0];
    assign req = {1'b1, 1'b1, av_write, my_id, av_byteenable, av_address[21:0], seq, av_writedata};

    assign av_readdatavalid = my_resp && !rin[66];
    assign av_readdata = rin[31:0];

endmodule
