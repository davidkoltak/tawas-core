//
// Shared RAM on a Raccoon Bus
//
// by
//   David M. Koltak  05/30/2017
//
// The MIT License (MIT)
// 
// Copyright (c) 2017 David M. Koltak
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

module sram
(
  CLK,
  RST,

  RaccIn,
  RaccOut
);
  parameter ADDR_MASK = 20'hF0000;
  parameter ADDR_BASE = 20'h10000;
  
  input CLK;
  input RST;

  input [63:0] RaccIn;
  output [63:0] RaccOut;
  
  wire [19:0] ADDR;
  wire CS;
  wire WE;
  wire [3:0] MASK;
  wire [31:0] DIN;
  wire [31:0] DOUT;
  
  raccoon2ram #(.ADDR_MASK(ADDR_MASK), .ADDR_BASE(ADDR_BASE)) raccoon2ram
  (
    .CLK(CLK),
    .RST(RST),

    .RaccIn(RaccIn),
    .RaccOut(RaccOut),

    .CS(CS),
    .WE(WE),
    .ADDR(ADDR),
    .MASK(MASK),
    .WR_DATA(DIN),
    .RD_DATA(DOUT)
  );
  
  reg [31:0] data_array[(1024 * 16)-1:0];
  reg [31:0] data_out;
  wire [31:0] bitmask;

  assign bitmask = {{8{MASK[3]}}, {8{MASK[2]}}, {8{MASK[1]}}, {8{MASK[0]}}};
  
  always @ (posedge CLK)
    if (CS && WE)
      data_array[ADDR[15:2]] <= (data_array[ADDR[15:2]] & ~bitmask) | (DIN & bitmask);
    
  always @ (posedge CLK)
    if (CS)
      data_out <= data_array[ADDR[15:2]];
  
  assign DOUT = data_out;
  
endmodule
