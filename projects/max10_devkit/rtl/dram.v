//
// Data RAM for Tawas Core
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

module dram
(
  input CLK,
  
  input [31:0] ADDR,
  input CS,
  input WR,
  input [3:0] MASK,
  input [31:0] DIN,
  output [31:0] DOUT
);

  parameter DRAM_DATA_FILE = "dram.hex";
  
  reg [31:0] data_array[(1024 * 16)-1:0];
  reg [31:0] data_out;
  wire [31:0] bitmask;
  
  initial
  begin
    $readmemh(DRAM_DATA_FILE, data_array);
  end

  assign bitmask = {{8{MASK[3]}}, {8{MASK[2]}}, {8{MASK[1]}}, {8{MASK[0]}}};
  
  always @ (posedge CLK)
    if (CS && WR)
      data_array[ADDR[15:2]] <= (data_array[ADDR[15:2]] & ~bitmask) | (DIN & bitmask);
    
  always @ (posedge CLK)
    if (CS)
      data_out <= data_array[ADDR[15:2]];
  
  assign DOUT = data_out;
  
endmodule
