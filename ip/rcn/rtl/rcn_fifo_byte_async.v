/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * Byte wide asynchronous fifo for use in RCN ip modules.
 *
 */

module rcn_fifo_byte_async
(
    input rst_in,
    input clk_in,
    input clk_out,

    input [7:0] din,
    input push,
    output full,

    output [7:0] dout,
    input pop,
    output empty
);

    reg [1:0] cross_in;
    reg [3:0] head_in;
    reg [3:0] head_snapshot;
    reg [3:0] tail_in;

    reg [1:0] cross_out;
    reg [3:0] head_out;
    reg [3:0] tail_out;
    reg [3:0] tail_snapshot;

    always @ (posedge clk_in)
        cross_in <= cross_out;

    always @ (posedge clk_out or posedge rst_in)
        if (rst_in)
            cross_out <= 2'b00;
        else
            case (cross_in)
            2'b00: cross_out <= 2'b01;
            2'b01: cross_out <= 2'b11;
            2'b11: cross_out <= 2'b10;
            default: cross_out <= 2'b00;
            endcase

    wire [3:0] head_in_next = head_in + 4'd1;
    wire fifo_full = (head_in_next == tail_in);

    always @ (posedge clk_in or posedge rst_in)
        if (rst_in)
        begin
            head_in <= 4'd0;
            head_snapshot <= 4'd0;
            tail_in <= 4'd0;
        end
        else
        begin
            if (push)
                head_in <= head_in_next;

            case (cross_in)
            2'b01: head_snapshot <= head_in;
            2'b10: tail_in <= tail_snapshot;
            endcase
        end

    wire [3:0] tail_out_next = tail_out + 4'd1;
    wire fifo_empty = (tail_out == head_out);

    always @ (posedge clk_out or posedge rst_in)
        if (rst_in)
        begin
            head_out <= 4'd0;
            tail_out <= 4'd0;
            tail_snapshot <= 4'd0;
        end
        else
        begin
            if (pop)
                tail_out <= tail_out_next;

            case (cross_out)
            2'b01: tail_snapshot <= tail_out;
            2'b10: head_out <= head_snapshot;
            endcase
        end

    reg [7:0] fifo[15:0];

    always @ (posedge clk_in)
        if (push)
            fifo[head_in] <= din[7:0];

    assign full = fifo_full;
    assign empty = fifo_empty;

    assign dout = fifo[tail_out];

endmodule
