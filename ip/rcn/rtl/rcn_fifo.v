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

    reg [1:0] head;
    reg [1:0] tail;
    reg [2:0] cnt;
    
    wire fifo_full = cnt[2];
    wire fifo_empty = (cnt == 3'd0);

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            head <= 2'd0;
            tail <= 2'd0;
            cnt <= 3'd0;
        end
        else
        begin
            if (push)
                head <= head + 2'd1;

            if (pop)
                tail <= tail + 2'd1;
            
            case ({push, pop})
            2'b10: cnt <= cnt + 3'd1;
            2'b01: cnt <= cnt - 3'd1;
            default: ;
            endcase
        end

    reg [67:0] fifo[3:0];

    always @ (posedge clk)
        if (push)
            fifo[head] <= rcn_in[67:0];

    assign full = fifo_full;
    assign empty = fifo_empty;

    assign rcn_out = {!fifo_empty, fifo[tail]};

endmodule
