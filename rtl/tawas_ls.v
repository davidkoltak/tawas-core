
//
// Tawas Load/Store:
//
// Perform load/store operations between the data bus and register file.
//
// by
//   David M. Koltak  02/11/2016
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

module tawas_ls
(
  input CLK,
  input RST,

  output [31:0] DADDR,
  output DCS,
  output DWR,
  output [3:0] DMASK,
  output [31:0] DOUT,
  input [31:0] DIN,

  input LS_OP_VLD,
  input [14:0] LS_OP,

  output [2:0] LS_PTR_SEL,
  input [31:0] LS_PTR,
  
  output [2:0] LS_STORE_SEL,
  input [31:0] LS_STORE,

  output LS_PTR_UPD_VLD,
  output [2:0] LS_PTR_UPD_SEL,
  output [31:0] LS_PTR_UPD,
  
  output LS_LOAD_VLD,
  output [2:0] LS_LOAD_SEL,
  output [31:0] LS_LOAD
);

  assign LS_PTR_SEL = 3'd0;
  assign LS_STORE_SEL = 3'd0;
  
  assign LS_PTR_UPD_VLD = 1'b0;
  assign LS_PTR_UPD_SEL = 3'd0;
  assign LS_PTR_UPD = 32'd0;
  
  assign LS_LOAD_VLD = 1'b0;
  assign LS_LOAD_SEL = 3'd0;
  assign  LS_LOAD_DATA = 32'd0;
  
endmodule
  
