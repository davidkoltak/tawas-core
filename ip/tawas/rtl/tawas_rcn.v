/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas RCN bus interface:
//
// Perform load/store operations over RCN. Stall issueing thread while transaction is pending.
//

module tawas_rcn
(
    input clk,
    input rst,

    input [1:0] slice,
    output [3:0] rcn_stall,

    input rcn_cs,
    input rcn_xch,
    input rcn_wr,
    input [31:0] rcn_addr,
    input [2:0] rcn_wbreg,
    input [3:0] rcn_mask,
    input [31:0] rcn_wdata,

    output reg rcn_load_vld,
    output reg [1:0] rcn_load_slice,
    output reg [2:0] rcn_load_sel,
    output reg [31:0] rcn_load,

    input [68:0] rcn_in,
    output [68:0] rcn_out
);
    parameter MASTER_ID = 0;

    wire [1:0] seq = slice + 2'd3;
    wire issue;
    wire [1:0] iss_seq;
    wire rdone;
    wire wdone;
    wire [1:0] rsp_seq;
    wire [3:0] rsp_mask;
    wire [31:0] rsp_data;

    rcn_master_buf #(.MASTER_ID(MASTER_ID)) rcn_master
    (
        .rst(rst),
        .clk(clk),

        .rcn_in(rcn_in),
        .rcn_out(rcn_out),

        .cs(rcn_cs),
        .seq(seq),
        .busy(),
        .wr(rcn_wr),
        .mask(rcn_mask),
        .addr(rcn_addr[23:0]),
        .wdata(rcn_wdata),

        .issue(issue),
        .iss_seq(iss_seq),

        .rdone(rdone),
        .wdone(wdone),
        .rsp_seq(rsp_seq),
        .rsp_mask(rsp_mask),
        .rsp_addr(),
        .rsp_data(rsp_data)
    );

    //
    // Counting pending transactions
    //

    reg [3:0] pending_0;
    wire pending_0_inc = rcn_cs && (seq == 2'b00);
    wire pending_0_dec = (rdone || wdone) && (rsp_seq == 2'b00);

    always @ (posedge clk or posedge rst)
        if (rst)
          pending_0 <= 4'd0;
        else
            case ({pending_0_inc, pending_0_dec})
            2'b01: pending_0 <= pending_0 - 4'd1;
            2'b10: pending_0 <= pending_0 + 4'd1;
            default: ;
            endcase

    reg [3:0] pending_1;
    wire pending_1_inc = rcn_cs && (seq == 2'b01);
    wire pending_1_dec = (rdone || wdone) && (rsp_seq == 2'b01);

    always @ (posedge clk or posedge rst)
        if (rst)
          pending_1 <= 4'd0;
        else
            case ({pending_1_inc, pending_1_dec})
            2'b01: pending_1 <= pending_1 - 4'd1;
            2'b10: pending_1 <= pending_1 + 4'd1;
            default: ;
            endcase

    reg [3:0] pending_2;
    wire pending_2_inc = rcn_cs && (seq == 2'b10);
    wire pending_2_dec = (rdone || wdone) && (rsp_seq == 2'b10);

    always @ (posedge clk or posedge rst)
        if (rst)
          pending_2 <= 4'd0;
        else
            case ({pending_2_inc, pending_2_dec})
            2'b01: pending_2 <= pending_2 - 4'd1;
            2'b10: pending_2 <= pending_2 + 4'd1;
            default: ;
            endcase

    reg [3:0] pending_3;
    wire pending_3_inc = rcn_cs && (seq == 2'b11);
    wire pending_3_dec = (rdone || wdone) && (rsp_seq == 2'b11);

    always @ (posedge clk or posedge rst)
        if (rst)
          pending_3 <= 4'd0;
        else
            case ({pending_3_inc, pending_3_dec})
            2'b01: pending_3 <= pending_3 - 4'd1;
            2'b10: pending_3 <= pending_3 + 4'd1;
            default: ;
            endcase

    wire [3:0] one_pending = {(pending_3 == 4'd1), (pending_2 == 4'd1),
                              (pending_1 == 4'd1), (pending_0 == 4'd1)};

    wire [3:0] max_pending = {(pending_3 == 4'd15), (pending_2 == 4'd15),
                              (pending_1 == 4'd15), (pending_0 == 4'd15)};

    //
    // Core thread stalls
    //

    reg [3:0] issue_stall;
    wire [3:0] set_issue_stall = (rcn_cs) ? (4'd1 << seq) : 4'd0;
    wire [3:0] clr_issue_stall = (issue) ? (4'd1 << iss_seq) : 4'd0;

    always @ (posedge clk or posedge rst)
        if (rst)
            issue_stall <= 4'd0;
        else
            issue_stall <= (issue_stall | set_issue_stall) & ~clr_issue_stall;

    wire read_stall_trans = rcn_cs && !rcn_wr;
    wire xch_stall_trans = rcn_cs && rcn_wr && rcn_xch;

    reg [3:0] pending_stall;
    wire [3:0] set_pending_stall = (read_stall_trans || xch_stall_trans) ?
                                   (4'd1 << seq) : 4'd0;
    wire [3:0] clr_pending_stall = (rdone || wdone) ?
                                   (4'd1 << rsp_seq) & (one_pending) : 4'd0;

    always @ (posedge clk or posedge rst)
        if (rst)
            pending_stall <= 4'd0;
        else
            pending_stall <= (pending_stall | set_pending_stall) & ~clr_pending_stall;

    assign rcn_stall = max_pending | issue_stall | pending_stall;

    //
    // Read retire
    //

    reg [2:0] wbreg[3:0];
    reg xch[3:0];

    always @ (posedge clk)
        if (rcn_cs)
        begin
            wbreg[seq] <= rcn_wbreg;
            xch[seq] <= rcn_wr && rcn_xch;
        end

    wire [31:0] rsp_data_adj = (rsp_mask[3:0] == 4'b1111) ? rsp_data[31:0] :
                               (rsp_mask[3:2] == 2'b11) ? {16'd0, rsp_data[31:16]} :
                               (rsp_mask[1:0] == 2'b11) ? {16'd0, rsp_data[15:0]} :
                               (rsp_mask[3]) ? {24'd0, rsp_data[31:24]} :
                               (rsp_mask[2]) ? {24'd0, rsp_data[23:16]} :
                               (rsp_mask[1]) ? {24'd0, rsp_data[15:8]} : {24'd0, rsp_data[7:0]};

    always @ (posedge clk)
    begin
        rcn_load_vld <= rdone || (wdone && xch[rsp_seq]);
        rcn_load_slice <= rsp_seq;
        rcn_load_sel <= wbreg[rsp_seq];
        rcn_load <= rsp_data_adj;
    end

endmodule
