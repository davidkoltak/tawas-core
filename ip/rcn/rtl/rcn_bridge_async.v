/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn bus asynchronous bridge.
 *
 */

module rcn_bridge_async
(
    input main_rst,
    input main_clk,
    input sub_clk,

    input [68:0] main_rcn_in,
    output [68:0] main_rcn_out,

    input [68:0] sub_rcn_in,
    output [68:0] sub_rcn_out
);
    parameter ID_MASK = 0;
    parameter ID_BASE = 1;
    parameter ADDR_MASK = 0;
    parameter ADDR_BASE = 1;

    wire [5:0] my_id_mask = ID_MASK;
    wire [5:0] my_id_base = ID_BASE;
    wire [23:0] my_addr_mask = ADDR_MASK;
    wire [23:0] my_addr_base = ADDR_BASE;

    reg [68:0] main_rin;
    reg [68:0] main_rout;

    reg [68:0] sub_rin;
    reg [68:0] sub_rout;

    assign main_rcn_out = main_rout;
    assign sub_rcn_out = sub_rout;

    wire [68:0] sub_fifo_in;
    wire sub_fifo_push;
    wire sub_fifo_full;
    wire [68:0] sub_fifo_out;
    wire sub_fifo_pop;
    wire sub_fifo_empty;

    wire [68:0] main_fifo_in;
    wire main_fifo_push;
    wire main_fifo_full;
    wire [68:0] main_fifo_out;
    wire main_fifo_pop;
    wire main_fifo_empty;

    always @ (posedge main_clk or posedge main_rst)
        if (main_rst)
        begin
            main_rin <= 69'd0;
            main_rout <= 69'd0;
        end
        else
        begin
            main_rin <= main_rcn_in;
            main_rout <=  (sub_fifo_pop) ? sub_fifo_out :
                          (main_fifo_push) ? 69'd0 : main_rin;
        end

    always @ (posedge sub_clk or posedge main_rst)
        if (main_rst)
        begin
            sub_rin <= 69'd0;
            sub_rout <= 69'd0;
        end
        else
        begin
            sub_rin <= sub_rcn_in;
            sub_rout <=  (main_fifo_pop) ? main_fifo_out :
                          (sub_fifo_push) ? 69'd0 : sub_rin;
        end

    wire main_id_match = ((main_rin[65:60] & my_id_mask) == my_id_base);
    wire main_addr_match = ((main_rin[55:34] & my_addr_mask[23:2]) == my_addr_base[23:2]);

    assign main_fifo_push = !main_fifo_full && main_rin[68] &&
                            ((main_rin[67] && main_addr_match) ||
                             (!main_rin[67] && main_id_match));

    assign main_fifo_pop = !main_fifo_empty && (!sub_rin[68] || sub_fifo_push);

    rcn_fifo_async main_fifo
    (
        .rst_in(main_rst),
        .clk_in(main_clk),
        .clk_out(sub_clk),

        .rcn_in(main_rin),
        .push(main_fifo_push),
        .full(main_fifo_full),

        .rcn_out(main_fifo_out),
        .pop(main_fifo_pop),
        .empty(main_fifo_empty)
    );

    wire sub_id_match = ((sub_rin[65:60] & my_id_mask) == my_id_base);
    wire sub_addr_match = ((sub_rin[55:34] & my_addr_mask[23:2]) == my_addr_base[23:2]);

    assign sub_fifo_push = !sub_fifo_full && sub_rin[68] &&
                            ((sub_rin[67] && !sub_addr_match) ||
                             (!sub_rin[67] && !sub_id_match));

    assign sub_fifo_pop = !sub_fifo_empty && (!main_rin[68] || main_fifo_push);

    rcn_fifo_async sub_fifo
    (
        .rst_in(main_rst),
        .clk_in(sub_clk),
        .clk_out(main_clk),

        .rcn_in(sub_rin),
        .push(sub_fifo_push),
        .full(sub_fifo_full),

        .rcn_out(sub_fifo_out),
        .pop(sub_fifo_pop),
        .empty(sub_fifo_empty)
    );

endmodule
