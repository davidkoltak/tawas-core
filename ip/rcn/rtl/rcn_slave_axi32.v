//
// RCN bus interface to 32-bit AXI style interface.
//
// by
//     David Koltak  11/01/2016
//
// The MIT License (MIT)
// 
// Copyright (c) 2016 David M. Koltak
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// 

module rcn_slave_axi32
(
  CLK,
  RST,

  RCN_IN,
  RCN_OUT,

  AWID,
  AWADDR,
  AWLEN,
  AWSIZE,
  AWBURST,
  AWLOCK,
  AWCACHE,
  AWPROT,
  AWVALID,
  AWREADY,

  WID,
  WDATA,
  WSTRB,
  WLAST,
  WVALID,
  WREADY,

  BID,
  BRESP,
  BVALID,
  BREADY,

  ARID,
  ARADDR,
  ARLEN,
  ARSIZE,
  ARBURST,
  ARLOCK,
  ARCACHE,
  ARPROT,
  ARVALID,
  ARREADY,

  RID,
  RDATA,
  RRESP,
  RLAST,
  RVALID,
  RREADY
);
  parameter ADDR_MASK = 20'hF0000;
  parameter ADDR_BASE = 20'h10000;
  parameter AXI_UPPER_12 = 12'h000;
  
  input CLK;
  input RST;

  input [63:0] RCN_IN;
  output [63:0] RCN_OUT;

  output [7:0] AWID;
  output [31:0] AWADDR;
  output [3:0] AWLEN;
  output [2:0] AWSIZE;
  output [1:0] AWBURST;
  output [1:0] AWLOCK;
  output [3:0] AWCACHE;
  output [2:0] AWPROT;
  output AWVALID;
  input AWREADY;

  output [7:0] WID;
  output [31:0] WDATA;
  output [3:0] WSTRB;
  output WLAST;
  output WVALID;
  input WREADY;

  input [7:0] BID;
  input [1:0] BRESP;
  input BVALID;
  output BREADY;

  output [7:0] ARID;
  output [31:0] ARADDR;
  output [3:0] ARLEN;
  output [2:0] ARSIZE;
  output [1:0] ARBURST;
  output [1:0] ARLOCK;
  output [3:0] ARCACHE;
  output [2:0] ARPROT;
  output ARVALID;
  input ARREADY;

  input [7:0] RID;
  input [31:0] RDATA;
  input [1:0] RRESP;
  input RLAST;
  input RVALID;
  output RREADY;

  reg [63:0] din;
  reg [63:0] dout;
  
  assign RCN_OUT = dout;
  
  reg pending_ar;
  reg [7:0] pending_ar_id;
  reg [31:0] pending_ar_addr;
  
  reg pending_aw;
  reg pending_w;
  reg [7:0] pending_aw_id;
  reg [31:0] pending_aw_addr;
  reg [31:0] pending_w_data;
  reg [3:0] pending_w_mask;
   
  wire addr_match = (din[63:62] == 2'b11) && (({din[49:32], 2'b00} & ADDR_MASK) == (ADDR_BASE & ADDR_MASK));
  
  wire req_is_read = |din[53:50];
  wire send_read_req = addr_match && !req_is_read && (!pending_ar || ARREADY);
  wire send_write_req = addr_match && req_is_read && (!pending_aw || AWREADY) && (!pending_w || WREADY);

  wire send_read_rsp = (!din[63] || send_read_req || send_write_req) && RVALID;
  wire send_read_rsp_err = |RRESP[1:0];
  wire send_write_rsp = (!din[63] || send_read_req || send_write_req) && BVALID;
  wire send_write_rsp_err = |BRESP[1:0];
  
  always @ (posedge CLK or posedge RST)
    if (RST)  
    begin
      din <= 64'd0;
      dout <= 64'd0;
      
      pending_ar <= 1'b0;
      pending_aw <= 1'b0;
      pending_w <= 1'b0;
    end
    else
    begin
      din <= RCN_IN;
      dout <= (send_read_req || send_write_req) ? 64'd0 : 
              (send_read_rsp) ? {2'b10, RID, 22'd0, RDATA} :
              (send_write_rsp) ? {2'b10, BID, 22'd0, 32'd0} : din;
      
      pending_ar <= (pending_ar || send_read_req) && !ARREADY;
      pending_aw <= (pending_aw || send_write_req) && !AWREADY;
      pending_w <= (pending_w || send_write_req) && !WREADY;
    end

  always @ (posedge CLK)
    if (send_read_req)
    begin
      pending_ar_id <= din[61:54];
      pending_ar_addr <= {AXI_UPPER_12, din[49:32], 2'b00};
    end
  
  always @ (posedge CLK)
    if (send_write_req)
    begin
      pending_aw_id <= din[61:54];
      pending_aw_addr <= {AXI_UPPER_12, din[49:32], 2'b00};
      pending_w_data <= din[31:0];
      pending_w_mask <= din[53:50];
    end
    
  assign ARID = pending_ar_id;
  assign ARADDR = pending_ar_addr;
  assign ARLEN = 4'd0;
  assign ARSIZE = 3'd2;
  assign ARBURST = 2'd0;
  assign ARLOCK = 2'd0;
  assign ARCACHE = 4'd0;
  assign ARPROT = 3'd0;
  assign ARVALID = pending_ar;

  assign AWID = pending_aw_id;
  assign AWADDR = pending_aw_addr;
  assign AWLEN = 4'd0;
  assign AWSIZE = 3'd2;
  assign AWBURST = 2'd0;
  assign AWLOCK = 2'd0;
  assign AWCACHE = 4'd0;
  assign AWPROT = 3'd0;
  assign AWVALID = pending_aw;

  assign WID = pending_aw_id;
  assign WDATA = pending_w_data;
  assign WSTRB = pending_w_mask;
  assign WLAST = 1'b1;
  assign WVALID = pending_w;
  
  assign RREADY = (!din[63] || send_read_req || send_write_req);
  assign BREADY = (!din[63] || send_read_req || send_write_req) && !RVALID;
  
endmodule
