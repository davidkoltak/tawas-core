/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas RCN bus interface:
//
// Perform load/store operations over RCN. Stall issueing thread while transaction is pending.
//
// by
//   David M. Koltak  5/22/2018
//

module tawas_rcn
(
    input CLK,
    input RST,
    
    input [1:0] SLICE,
    output reg [3:0] RCN_STALL,
    
    input [31:0] DADDR,
    input RCN_CS,
    input [3:0] WRITEBACK_REG,
    input DWR,
    input [3:0] DMASK,
    input [31:0] DOUT,
      
    output reg RCN_LOAD_VLD,
    output reg [1:0] RCN_LOAD_SLICE,
    output reg [3:0] RCN_LOAD_SEL,
    output reg [31:0] RCN_LOAD,
    
    input [66:0] RCN_IN,
    output [66:0] RCN_OUT
);
    parameter MASTER_ID = 0;
    
    wire rdone;
    wire wdone;
    wire [1:0] rsp_seq;
    wire [3:0] rsp_mask;
    wire [31:0] rsp_data;

    rcn_master_buf #(.MASTER_ID(MASTER_ID)) rcn_master
    (
        .rst(RST),
        .clk(CLK),
        
        .rcn_in(RCN_IN),
        .rcn_out(RCN_OUT),
        
        .cs(RCN_CS),
        .seq(SLICE),
        .busy(),
        .wr(DWR),
        .mask(DMASK),
        .addr(DADDR[21:0]),
        .wdata(DOUT),
        
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
    
    wire [3:0] set_stall = (RCN_CS) ? (4'd1 << SLICE) : 4'd0;
    wire [3:0] clr_stall = (rdone || wdone) ? (4'd1 << rsp_seq) : 4'd0;
    
    always @ (posedge CLK or posedge RST)
        if (RST)
            RCN_STALL <= 4'd0;
        else
            RCN_STALL <= (RCN_STALL | set_stall) & ~clr_stall;

    //
    // Read retire
    //
    
    reg [3:0] wb_reg[3:0];
    
    always @ (posedge CLK)
        if (RCN_CS)
            wb_reg[SLICE] <= WRITEBACK_REG;

    wire [31:0] rsp_data_adj = (rsp_mask[3:0] == 4'b1111) ? rsp_data[31:0] :
                               (rsp_mask[3:2] == 2'b11) ? {16'd0 : rsp_data[31:16]} :
                               (rsp_mask[1:0] == 2'b11) ? {16'd0 : rsp_data[15:0]} :
                               (rsp_mask[3]) {24'd0, rsp_data[31:24]} :
                               (rsp_mask[2]) {24'd0, rsp_data[23:16]} :
                               (rsp_mask[1]) {24'd0, rsp_data[15:8]} : {24'd0, rsp_data[7:0]};

    always @ (posedge CLK)
    begin
        RCN_LOAD_VLD <= rdone;
        RCN_LOAD_SLICE <= rsp_seq;
        RCN_LOAD_SEL <= wb_reg[rsp_seq];
        RCN_LOAD <= rsp_data_adj;
    end
  
endmodule
