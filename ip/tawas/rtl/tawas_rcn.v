/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas RCN bus interface:
//
// Perform load/store operations over RCN. 
// Stall issueing thread while transaction is pending.
// Stall all threads if bus backpressure fills issue buffer.
//

module tawas_rcn
(
    input clk,
    input rst,

    input [4:0] thread_decode,
    output [31:0] rcn_stall,

    input rcn_cs,
    input rcn_xch,
    input rcn_wr,
    input [31:0] rcn_addr,
    input [2:0] rcn_wbreg,
    input [3:0] rcn_mask,
    input [31:0] rcn_wdata,

    output reg rcn_load_en,
    output reg [4:0] rcn_load_thread,
    output reg [2:0] rcn_load_reg,
    output reg [31:0] rcn_load_data,

    input [68:0] rcn_in,
    output [68:0] rcn_out
);
    parameter MASTER_GROUP_8 = 0;

    reg [4:0] seq;
    wire rdone;
    wire wdone;
    wire [4:0] rsp_seq;
    wire [3:0] rsp_mask;
    wire [31:0] rsp_data;
    wire master_full;
    
    always @ (posedge clk)
        seq <= thread_decode;

    tawas_rcn_master_buf #(.MASTER_GROUP_8(MASTER_GROUP_8)) rcn_master
    (
        .rst(rst),
        .clk(clk),

        .rcn_in(rcn_in),
        .rcn_out(rcn_out),

        .cs(rcn_cs),
        .seq(seq),
        .wr(rcn_wr),
        .mask(rcn_mask),
        .addr(rcn_addr[23:0]),
        .wdata(rcn_wdata),

        .full(master_full),

        .rdone(rdone),
        .wdone(wdone),
        .rsp_seq(rsp_seq),
        .rsp_mask(rsp_mask),
        .rsp_addr(),
        .rsp_data(rsp_data)
    );

    //
    // Core thread stalls
    //

    reg rdone_d1;
    reg rdone_d2;
    reg rdone_d3;
    reg wdone_d1;
    reg wdone_d2;
    reg wdone_d3;
    reg [4:0] rsp_seq_d1;
    reg [4:0] rsp_seq_d2;
    reg [4:0] rsp_seq_d3;
    
    always @ (posedge clk)
    begin
        rdone_d1 <= rdone;
        rdone_d2 <= rdone_d1;
        rdone_d3 <= rdone_d2;
        wdone_d1 <= wdone;
        wdone_d2 <= wdone_d1;
        wdone_d3 <= wdone_d2;
        rsp_seq_d1 <= rsp_seq;
        rsp_seq_d2 <= rsp_seq_d1;
        rsp_seq_d3 <= rsp_seq_d2;
    end
    
    reg [31:0] pending_stall;
    wire [31:0] set_pending_stall = (rcn_cs) ? (32'd1 << seq) : 32'd0;
    wire [31:0] clr_pending_stall = (rdone_d3 || wdone_d3) ? (32'd1 << rsp_seq_d3) : 32'd0;

    always @ (posedge clk or posedge rst)
        if (rst)
            pending_stall <= 32'd0;
        else
            pending_stall <= (pending_stall | set_pending_stall) & ~clr_pending_stall;

    assign rcn_stall = pending_stall | {32{master_full}};

    //
    // Read retire
    //

    reg [2:0] wbreg[31:0];
    reg xch[31:0];

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

    always @ *
    begin
        rcn_load_en = rdone || (wdone && xch[rsp_seq]);
        rcn_load_thread = rsp_seq;
        rcn_load_reg = wbreg[rsp_seq];
        rcn_load_data = rsp_data_adj;
    end
    
endmodule
