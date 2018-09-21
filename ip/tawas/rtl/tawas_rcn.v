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

    input [4:0] thread_store,
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

    wire [4:0] seq = thread_store;
    wire issue;
    wire [4:0] iss_seq;
    wire rdone;
    wire wdone;
    wire [4:0] rsp_seq;
    wire [3:0] rsp_mask;
    wire [31:0] rsp_data;

    tawas_rcn_master_buf #(.MASTER_GROUP_8(MASTER_GROUP_8)) rcn_master
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
    // Read retire
    //

    reg [31:0] wb_data
    wire [31:0] rsp_data_adj = (rsp_mask[3:0] == 4'b1111) ? rsp_data[31:0] :
                               (rsp_mask[3:2] == 2'b11) ? {16'd0, rsp_data[31:16]} :
                               (rsp_mask[1:0] == 2'b11) ? {16'd0, rsp_data[15:0]} :
                               (rsp_mask[3]) ? {24'd0, rsp_data[31:24]} :
                               (rsp_mask[2]) ? {24'd0, rsp_data[23:16]} :
                               (rsp_mask[1]) ? {24'd0, rsp_data[15:8]} : {24'd0, rsp_data[7:0]};

    always @ (posedge clk)
    begin
        rcn_load_en <= rdone;
        rcn_load_thread <= 5'd0;
        rcn_load_reg <= 3'd0;
        rcn_load_data <= rsp_data_adj;
    end

    //
    // Count pending writes and stall when 6 are pending
    //
    
    wire [31:0] wr_issue = (rcn_cs && rcn_wr) ? (1 << thread_store) : 32'd0;
    wire [31:0] wr_done = (wdone) ? (1 << rsp_seq) : 32'd0;
    reg [2:0] wr_pending[31:0];
    reg [31:0] wr_stall;
    integer pwc;
    
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            wr_stall <= 32'd0;
            for (pwc = 0; pwc < 32; pwc = pwc + 1)
                wr_pending[pwc] <= 3'd0;
        end
        else
            for (pwc = 0; pwc < 32; pwc = pwc + 1)
            begin
                case (wr_issue[pwc], wr_done[pwc])
                2'b10: wr_pending[pwc] <= wr_pending[pwc] + 3'd1;
                2'b01: wr_pending[pwc] <= wr_pending[pwc] - 3'd1;
                default: ;
                endcase
                
                wr_stall[pwc] <= (wr_pending[pwc][2:1] == 2'b11);
            end
endmodule
