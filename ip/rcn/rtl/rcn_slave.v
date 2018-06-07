/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn bus slave interface - one cycle read delay
 *
 */

module rcn_slave
(
    input rst,
    input clk,

    input [68:0] rcn_in,
    output [68:0] rcn_out,

    output cs,
    output wr,
    output [3:0] mask,
    output [23:0] addr,
    output [31:0] wdata,
    input [31:0] rdata
);
    parameter ADDR_MASK = 0;
    parameter ADDR_BASE = 1;

    reg [68:0] rin;
    reg [68:0] rin_d1;
    reg [68:0] rout;

    assign rcn_out = rout;

    wire [23:0] my_mask = ADDR_MASK;
    wire [23:0] my_base = ADDR_BASE;

    wire my_req = rin[68] && rin[67] && ((rin[55:34] & my_mask[23:2]) == my_base[23:2]);
    reg my_req_d1;

    wire [68:0] my_resp;

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
            rout <= (my_req_d1) ? my_resp : rin_d1;
        end

    assign cs = my_req;
    assign wr = rin[66];
    assign mask = rin[59:56];
    assign addr = {rin[55:34], 2'd0};
    assign wdata = rin[31:0];

    assign my_resp = {1'b1, 1'b0, rin_d1[66:32], rdata};

endmodule
