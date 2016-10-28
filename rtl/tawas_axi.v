
//
// Tawas AXI bus interface:
//
// Perform load/store operations over AXI. Stall issueing thread while transaction is pending.
//
// by
//   David M. Koltak  10/28/2016
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

module tawas_axi
(
  input CLK,
  input RST,

  input [1:0] SLICE,
  output [3:0] AXI_STALL,
  
  input [31:0] DADDR,
  input AXI_CS,
  input DWR,
  input [3:0] DMASK,
  input [31:0] DOUT,
      
  output AXI_LOAD_VLD,
  output [1:0] AXI_LOAD_SLICE,
  output [2:0] AXI_LOAD_SEL,
  output [31:0] AXI_LOAD,
  
  output [1:0] AWID,
  output [31:0] AWADDR,
  output [3:0] AWLEN,
  output [2:0] AWSIZE,
  output [1:0] AWBURST,
  output [1:0] AWLOCK,
  output [3:0] AWCACHE,
  output [2:0] AWPROT,
  output AWVALID,
  input AWREADY,

  output [1:0] WID,
  output [63:0] WDATA,
  output [7:0] WSTRB,
  output WLAST,
  output WVALID,
  input WREADY,

  input [1:0] BID,
  input [1:0] BRESP,
  input BVALID,
  output BREADY,

  output [1:0] ARID,
  output [31:0] ARADDR,
  output [3:0] ARLEN,
  output [2:0] ARSIZE,
  output [1:0] ARBURST,
  output [1:0] ARLOCK,
  output [3:0] ARCACHE,
  output [2:0] ARPROT,
  output ARVALID,
  input ARREADY,

  input [1:0] RID,
  input [63:0] RDATA,
  input [1:0] RRESP,
  input RLAST,
  input RVALID,
  output RREADY
);

endmodule
