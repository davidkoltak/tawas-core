//
// Intel PSG Max 10 DevKit Reference Design
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

module max10_devkit_top 
(
  input clk_50,
  input fpga_reset_n,

  output qspi_clk,
  inout [3:0] qspi_io,
  output qspi_csn,
  
  input uart_rx,
  output uart_tx,
  
  output [4:0] user_led,
  input [3:0] user_pb
);

  wire irom_cs;
  wire [23:0] irom_addr;
  wire [31:0] irom_data;
  
  irom irom
  (
    .CLK(clk_50),

    .ADDR(irom_addr),
    .CS(irom_cs),
    .DOUT(irom_data)
  );

  wire [31:0] dram_addr;
  wire dram_cs;
  wire dram_wr;
  wire [3:0] dram_mask;
  wire [31:0] dram_din;
  wire [31:0] dram_dout;
    
  dram dram
  (
    .CLK(clk_50),

    .ADDR(dram_addr),
    .CS(dram_cs),
    .WR(dram_wr),
    .MASK(dram_mask),
    .DIN(dram_din),
    .DOUT(dram_dout)
  );

  wire [79:0] RaccOut;
  wire [79:0] RaccIn;
  
  tawas tawas
  (
    .CLK(clk_50),
    .RST(!fpga_reset_n),

    .ICS(irom_cs),
    .IADDR(irom_addr),
    .IDATA(irom_data),

    .DADDR(dram_addr),
    .DCS(dram_cs),
    .DWR(dram_wr),
    .DMASK(dram_mask),
    .DOUT(dram_din),
    .DIN(dram_dout),
    
    .RaccOut(RaccOut),
    .RaccIn(RaccIn)
  );

  sram #(.ADDR_MASK(32'hFFFF0000), .ADDR_BASE(32'h00010000)) sram
  (
    .CLK(clk_50),
    .RST(!fpga_reset_n),

    .RaccIn(RaccOut),
    .RaccOut(RaccIn)
  );
  
endmodule