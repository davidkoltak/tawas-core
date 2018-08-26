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
    parameter DEPTH = 4; // max 32

    reg [4:0] head;
    reg [4:0] tail;
    reg [5:0] cnt;

    wire fifo_full = (cnt == DEPTH);
    wire fifo_empty = (cnt == 0);

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            head <= 5'd0;
            tail <= 5'd0;
            cnt <= 6'd0;
        end
        else
        begin
            if (push)
                head <= (head == (DEPTH - 1)) ? 5'd0 : head + 5'd1;

            if (pop)
                tail <= (tail == (DEPTH - 1)) ? 5'd0 : tail + 5'd1;

            case ({push, pop})
            2'b10: cnt <= cnt + 6'd1;
            2'b01: cnt <= cnt - 6'd1;
            default: ;
            endcase
        end

    reg [67:0] fifo[(DEPTH - 1):0];

    always @ (posedge clk)
        if (push)
            fifo[head] <= rcn_in[67:0];

    assign full = fifo_full;
    assign empty = fifo_empty;

    assign rcn_out = {!fifo_empty, fifo[tail]};

endmodule
