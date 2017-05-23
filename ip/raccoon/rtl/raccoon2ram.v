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

  input [79:0] RaccIn;
  output [79:0] RaccOut;

  output CS;
  output WE;
  output [31:0] ADDR;
  output [3:0] MASK;
  output [31:0] WR_DATA;
  input [31:0] RD_DATA;

  reg [79:0] din;
  reg [79:0] din_d1;
  reg [79:0] dout;
  
  assign RaccOut = dout;
  
  wire addr_match = din[79] && (din[77:76] == 2'b00) && ((din[31:0] & ADDR_MASK) == (ADDR_BASE & ADDR_MASK));
  reg addr_match_d1;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      din <= 80'd0;
      addr_match_d1 <= 1'b0;
      din_d1 <= 80'd0;
      dout <= 80'd0;
    end
    else
    begin
      din <= RaccIn;
      addr_match_d1 <= addr_match;
      din_d1 <= din;
      dout <= (addr_match_d1) ? {din_d1[79:78], 2'b10, din_d1[75:64], RD_DATA[31:0], din_d1[31:0]} : din_d1[79:0];
    end
   
  assign CS = addr_match;
  assign WE = din[78];
  assign ADDR = din[31:0];
  assign MASK = din[67:64];
  assign WR_DATA = din[63:32];
  
endmodule
