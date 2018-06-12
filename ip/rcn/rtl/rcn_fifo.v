/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn transaction fifo.
 *
 */

module rcn_fifo
(
    input rst,
    input clk,

    input [68:0] rcn_in,
    input push,
    output full,

    output [68:0] rcn_out,
    input pop,
    output empty
);

    reg [3:0] head;
    reg [3:0] tail;

    wire [3:0] head_next = head + 4'd1;
    wire fifo_full = (head_next == tail);
    wire fifo_empty = (head == tail);

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            head <= 4'd0;
            tail <= 4'd0;
        end
        else
        begin
            if (push & !fifo_full)
                head <= head_next;

            if (pop & !fifo_empty)
                tail <= tail + 4'd1;
        end

    reg [67:0] fifo[15:0];

    always @ (posedge clk)
        if (rcn_in[68] & !fifo_full)
            fifo[head] <= rcn_in[67:0];

    assign full = fifo_full;
    assign empty = fifo_empty;

    assign rcn_out = {!fifo_empty, fifo[tail]};

endmodule
