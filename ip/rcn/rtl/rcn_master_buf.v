/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn bus master interface with 4 entry request buffer.
 *
 * rcn bus vector definition =
 *   {valid, pending, id[3:0], seq[1:0], we[3:0], addr[19:0], data[31:0]}
 */

module rcn_master_buf
(
    input rst,
    input clk,
    
    input [66:0] rcn_in,
    output [66:0] rcn_out,
    
    input cs,
    input [1:0] seq,
    output busy,
    input wr,
    input [3:0] mask,
    input [21:0] addr,
    input [31:0] wdata,
    
    output rdone,
    output wdone,
    output [1:0] rsp_seq,
    output [3:0] rsp_mask,
    output [21:0] rsp_addr,
    output [31:0] rsp_data
);
    parameter MASTER_ID = 0;
    
    reg [58:0] req_buf[3:0];
    reg [1:0] write_ptr;
    reg [1:0] read_ptr;
    reg [2:0] req_cnt;
    assign busy = !req_cnt[2];
    wire req_push = cs && !req_cnt[2];
    wire req_pop;
    
    always @ (posedge CLK or posedge RST)
        if (RST)
            req_cnt <= 3'd0;
        else
            case ({req_push, req_pop})
            2'b10: req_cnt <= req_cnt + 3'd1;
            2'd01: req_cnt <= req_cnt - 3'd1;
            default: ;
            endcase
  
    always @ (posedge CLK or posedge RST)
        if (RST)
            write_ptr <= 2'd0;
        else if (req_push)
            write_ptr <= write_ptr + 2'd1;
  
    always @ (posedge CLK or posedge RST)
        if (RST)
            read_ptr <= 2'd0;
        else if (req_pop)
            read_ptr <= read_ptr + 2'd1;
  

    always @ (posedge CLK)
        if (req_push)
            req_buf[write_ptr] <= {seq, wr, mask[3:0], addr[21:2], wdata[31:0]};
  
  wire req_vld = (req_cnt[2:0] != 3'd0);
  wire [57:0] req = req_buf[read_ptr][57:0];
  wire req_busy;

  assign req_pop = req_vld && !req_busy;
  
  rcn_master #(.MASTER_ID(MASTER_ID)) rcn_master
  (
      .rst(rst),
      .clk(clk),
      
      .rcn_in(rcn_in),
      .rcn_out(rcn_out),
      
      .cs(req_vld),
      .seq(req[58:57]),
      .busy(req_busy),
      .wr(req[56]),
      .mask(req[55:52]),
      .addr({req[51:32], 2'd0}),
      .wdata(req[31:0]),
      
      .rdone(rdone),
      .wdone(wdone),
      .rsp_seq(rsp_seq),
      .rsp_mask(rsp_mask),
      .rsp_addr(rsp_addr),
      .rsp_data(rsp_data)
  );

endmodule
