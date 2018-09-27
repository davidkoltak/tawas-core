/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * S/GMII cycle asynchronous fifo.
 *
 */

module sgmii_fifo
(
    input rst_in,
    input clk_in,
    input clk_out,

    input [8:0] fifo_in,
    input push,
    output full,

    output [8:0] fifo_out,
    input pop,
    output empty
);
    parameter DEPTH = 32; // max 64 (can hold DEPTH-1 before full)
    parameter TRIG_DEPTH = 12; // Hold sync until push stops or X in a row
    
    reg [5:0] trig_cnt;
    wire trig_en = (!push || (trig_cnt == TRIG_DEPTH));
    
    always @ (posedge clk_in or posedge rst_in)
        if (rst_in)
            trig_cnt <= 6'd0;
        else if (!push)
            trig_cnt <= 6'd0;
        else if (!trig_en)
            trig_cnt <= trig_cnt + 6'd1;
    
    reg [1:0] cross_in;
    reg [5:0] head_in;
    reg [5:0] head_snapshot;
    reg [5:0] tail_in;

    reg [1:0] cross_out;
    reg [5:0] head_out;
    reg [5:0] tail_out;
    reg [5:0] tail_snapshot;

    always @ (posedge clk_in)
        cross_in <= (trig_en) ? cross_out : 2'd0;

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

    wire [5:0] head_in_next = (head_in == (DEPTH - 1)) ? 6'd0 : head_in + 6'd1;
    wire fifo_full = (head_in_next == tail_in);

    always @ (posedge clk_in or posedge rst_in)
        if (rst_in)
        begin
            head_in <= 6'd0;
            head_snapshot <= 6'd0;
            tail_in <= 6'd0;
        end
        else
        begin
            if (push && !fifo_full)
                head_in <= head_in_next;

            case (cross_in)
            2'b01: head_snapshot <= head_in;
            2'b10: tail_in <= tail_snapshot;
            endcase
        end

    wire [5:0] tail_out_next = (tail_out == (DEPTH - 1)) ? 6'd0 : tail_out + 6'd1;
    wire fifo_empty = (tail_out == head_out);

    always @ (posedge clk_out or posedge rst_in)
        if (rst_in)
        begin
            head_out <= 6'd0;
            tail_out <= 6'd0;
            tail_snapshot <= 6'd0;
        end
        else
        begin
            if (pop && !fifo_empty)
                tail_out <= tail_out_next;

            case (cross_out)
            2'b01: tail_snapshot <= tail_out;
            2'b10: head_out <= head_snapshot;
            endcase
        end

    reg [8:0] fifo[(DEPTH - 1):0];

    always @ (posedge clk_in)
        if (push)
            fifo[head_in] <= fifo_in[8:0];

    assign full = fifo_full;
    assign empty = fifo_empty;

    assign fifo_out = fifo[tail_out];

endmodule
