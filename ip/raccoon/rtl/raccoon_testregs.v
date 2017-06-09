//
// Test register module for Raccoon Bus
//   0x00 : Thread ID
//   0x04 : Test Progress Mark
//   0x08 : Test Fail
//   0x0C : Test Pass
//
// by
//     David Koltak  06/08/2017
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

module raccoon_testregs
(
  CLK,
  RST,

  TEST_PROGRESS,
  TEST_FAIL,
  TEST_PASS,
  
  RaccIn,
  RaccOut
);
  parameter ADDR_MASK = 20'hFFFF0;
  parameter ADDR_BASE = 20'hFFFF0;
  
  input CLK;
  input RST;

  output reg [31:0] TEST_PROGRESS;
  output reg [31:0] TEST_FAIL;
  output reg [31:0] TEST_PASS;
  
  input [63:0] RaccIn;
  output [63:0] RaccOut;
  
  reg [63:0] din;
  reg [63:0] din_d1;
  reg [63:0] dout;
  
  assign RaccOut = dout;
  
  wire addr_match = (din[63:62] == 2'b11) && (({din[49:32], 2'b00} & ADDR_MASK) == (ADDR_BASE & ADDR_MASK));
  reg addr_match_d1;
  
  reg [31:0] reg_out;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      din <= 64'd0;
      addr_match_d1 <= 1'b0;
      din_d1 <= 64'd0;
      dout <= 64'd0;
    end
    else
    begin
      din <= RaccIn;
      addr_match_d1 <= addr_match;
      din_d1 <= din;
      dout <= (addr_match_d1) ? {2'b10, din_d1[61:32], reg_out} : din_d1[63:0];
    end
  
  always @ (posedge CLK)
    if (addr_match)
      case (din[33:32])
      2'd0: reg_out <= {24'd0, din[61:54]};
      2'd1: reg_out <= TEST_PROGRESS;
      2'd2: reg_out <= TEST_FAIL;
      default: reg_out <= TEST_PASS;
      endcase
    
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      TEST_PROGRESS <= 32'd0;
      TEST_FAIL <= 32'd0;
      TEST_PASS <= 32'd0;
    end
    else if (addr_match && &din[53:50])
      case (din[33:32])
      2'd0: ;
      2'd1: TEST_PROGRESS <= din[31:0];
      2'd2: TEST_FAIL <= din[31:0];
      default: TEST_PASS <= din[31:0];
      endcase
      
endmodule
