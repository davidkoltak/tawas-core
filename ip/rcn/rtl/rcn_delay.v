//
// RCN bus sync delay
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

module rcn_delay
(
  CLK,
  RST,

  RCN_IN,
  RCN_OUT
);
  parameter DELAY_CYCLES = 7;

  input CLK;
  input RST;
  
  input [63:0] RCN_IN;
  output [63:0] RCN_OUT;
  
  reg [63:0] bus_delay[(DELAY_CYCLES-1):0];
  
  integer x;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      for (x = 0; x < DELAY_CYCLES; x = x + 1)
        bus_delay[x] <= 64'd0;
    end
    else
    begin
      bus_delay[(DELAY_CYCLES-1)] <= RCN_IN;
      for (x = 1; x < DELAY_CYCLES; x = x + 1)
        bus_delay[x-1] <= bus_delay[x];
    end
  
  assign RCN_OUT = bus_delay[0];
  // add a comment from working copy
endmodule
