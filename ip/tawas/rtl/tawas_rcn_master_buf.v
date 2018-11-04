/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn bus master interface with 32 entry request buffer.
 *
 */

module tawas_rcn_master_buf
(
    input rst,
    input clk,

    input [68:0] rcn_in,
    output [68:0] rcn_out,

    input cs,
    input [4:0] seq,
    input wr,
    input [3:0] mask,
    input [23:0] addr,
    input [31:0] wdata,

    output full,

    output rdone,
    output wdone,
    output [4:0] rsp_seq,
    output [3:0] rsp_mask,
    output [23:0] rsp_addr,
    output [31:0] rsp_data
);
    parameter MASTER_GROUP_8 = 0;
    parameter DEPTH = 16; // max 64
    
    reg [63:0] req_buf[(DEPTH - 1):0];
    reg [5:0] write_ptr;
    reg [5:0] read_ptr;
    reg [6:0] req_cnt;
    assign full = (req_cnt >= (DEPTH - 5));
    wire req_push = cs && (req_cnt != DEPTH);
    wire req_pop;

    always @ (posedge clk or posedge rst)
        if (rst)
            req_cnt <= 7'd0;
        else
            case ({req_push, req_pop})
            2'b10: req_cnt <= req_cnt + 7'd1;
            2'd01: req_cnt <= req_cnt - 7'd1;
            default: ;
            endcase

    always @ (posedge clk or posedge rst)
        if (rst)
            write_ptr <= 6'd0;
        else if (req_push)
            write_ptr <= (write_ptr == (DEPTH - 1)) ? 6'd0 : write_ptr + 6'd1;

    always @ (posedge clk or posedge rst)
        if (rst)
            read_ptr <= 6'd0;
        else if (req_pop)
            read_ptr <= (read_ptr == (DEPTH - 1)) ? 6'd0 : read_ptr + 6'd1;

    always @ (posedge clk)
        if (req_push)
            req_buf[write_ptr] <= {seq, wr, mask[3:0], addr[23:2], wdata[31:0]};

  wire req_vld = (req_cnt != 0);
  wire [63:0] req = req_buf[read_ptr][63:0];
  wire req_busy;

  assign req_pop = req_vld && !req_busy;

  tawas_rcn_master #(.MASTER_GROUP_8(MASTER_GROUP_8)) rcn_master
  (
      .rst(rst),
      .clk(clk),

      .rcn_in(rcn_in),
      .rcn_out(rcn_out),

      .cs(req_vld),
      .seq(req[63:59]),
      .busy(req_busy),
      .wr(req[58]),
      .mask(req[57:54]),
      .addr({req[53:32], 2'd0}),
      .wdata(req[31:0]),

      .rdone(rdone),
      .wdone(wdone),
      .rsp_seq(rsp_seq),
      .rsp_mask(rsp_mask),
      .rsp_addr(rsp_addr),
      .rsp_data(rsp_data)
  );

endmodule
