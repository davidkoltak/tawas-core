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
    output reg [3:0] rcn_stall,
    
    input [31:0] daddr,
    input rcn_cs,
    input [3:0] writeback_reg,
    input dwr,
    input [3:0] dmask,
    input [31:0] dout,
      
    output reg rcn_load_vld,
    output reg [1:0] rcn_load_slice,
    output reg [3:0] rcn_load_sel,
    output reg [31:0] rcn_load,
    
    input [66:0] rcn_in,
    output [66:0] rcn_out
);
    parameter MASTER_ID = 0;
    
    wire [1:0] seq = slice + 2'd2;
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
        .wr(dwr),
        .mask(dmask),
        .addr(daddr[21:0]),
        .wdata(dout),
        
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
    
    wire [3:0] set_stall = (rcn_cs) ? (4'd1 << seq) : 4'd0;
    wire [3:0] clr_stall = (rdone || wdone) ? (4'd1 << rsp_seq) : 4'd0;
    
    always @ (posedge clk or posedge rst)
        if (rst)
            rcn_stall <= 4'd0;
        else
            rcn_stall <= (rcn_stall | set_stall) & ~clr_stall;

    //
    // Read retire
    //
    
    reg [3:0] wb_reg[3:0];
    
    always @ (posedge clk)
        if (rcn_cs)
            wb_reg[seq] <= writeback_reg;

    wire [31:0] rsp_data_adj = (rsp_mask[3:0] == 4'b1111) ? rsp_data[31:0] :
                               (rsp_mask[3:2] == 2'b11) ? {16'd0, rsp_data[31:16]} :
                               (rsp_mask[1:0] == 2'b11) ? {16'd0, rsp_data[15:0]} :
                               (rsp_mask[3]) ? {24'd0, rsp_data[31:24]} :
                               (rsp_mask[2]) ? {24'd0, rsp_data[23:16]} :
                               (rsp_mask[1]) ? {24'd0, rsp_data[15:8]} : {24'd0, rsp_data[7:0]};

    always @ (posedge clk)
    begin
        rcn_load_vld <= rdone;
        rcn_load_slice <= rsp_seq;
        rcn_load_sel <= wb_reg[rsp_seq];
        rcn_load <= rsp_data_adj;
    end
  
endmodule
