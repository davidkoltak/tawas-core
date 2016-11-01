//
// Raccoon bus interface to generic RAM style interface.
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

module raccoon2ram
(
  CLK,
  RST,

  RaccIn,
  RaccOut,

  CS,
  WAIT,
  WE,
  ADDR,
  MASK,
  WR_DATA,
  RD_DATA
);
  parameter ADDR_MASK = 32'hFFFF0000;
  parameter ADDR_BASE = 32'h00010000;
  
  input CLK;
  input RST;

  input [78:0] RaccIn;
  output [78:0] RaccOut;

  output CS;
  input WAIT;
  output WE;
  output [31:0] ADDR;
  output [3:0] MASK;
  output [31:0] WR_DATA;
  input [31:0] RD_DATA;

  reg [78:0] din;
  reg [78:0] din_req;
  reg [78:0] din_rsp;
  reg [78:0] dout;
  
  wire rsp_pend = din_rsp[78] && (din[78] && !addr_match);
  wire req_pend = rsp_pend || (din_req[78] && WAIT);
  wire addr_match = din[78] && !req_pend && ((din[31:0] & ADDR_MASK) == (ADDR_BASE & ADDR_MASK));

  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      din <= 79'd0;
      din_req <= 79'd0;
      din_rsp <= 79'd0;
      dout <= 79'd0;
    end
    else
    begin
      din <= RaccIn;
      din_req <= (addr_match) ? din : (!WAIT) ? 79'd0 : din_req;
      din_rsp <= (din_req[78] && !WAIT && !rsp_pend) ? {din_req[78:77], 1'b1, din_req[75:64], RD_DATA[32:0], din_req[31:0]} : (!dout[78]) ? 79'd0 : din_rsp;
      dout <= (!din_rsp || (din[78] && !addr_match)) ? din : din_rsp;
    end
   
  assign CS = din_req[78] && !rsp_pend;
  assign WE = din_req[77];
  assign ADDR = din_req[31:0];
  assign MASK = din_req[67:64];
  assign WR_DATA = din_req[63:32];
  
endmodule
