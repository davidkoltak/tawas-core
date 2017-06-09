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

  assign user_led = 5'b0;
  
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

  wire [3:0] EventPending;
  
  wire [31:0] TEST_PROGRESS;
  wire [31:0] TEST_FAIL;
  wire [31:0] TEST_PASS;
  
  wire [63:0] RaccCore2Event;
  wire [63:0] RaccEvent2Test;
  wire [63:0] RaccTest2Ram;
  wire [63:0] RaccRam2Core;
  
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
    
    .RaccOut(RaccCore2Event),
    .RaccIn(RaccRam2Core)
  );

  raccoon_event #(.ADDR_MASK(20'hFFFE0), .ADDR_BASE(20'hE0000)) raccoon_event
  (
    .CLK(clk_50),
    .RST(!fpga_reset_n),

    .EventPending(EventPending),
  
    .RaccIn(RaccCore2Event),
    .RaccOut(RaccEvent2Test)
  );

  raccoon_testregs #(.ADDR_MASK(20'hFFFF0), .ADDR_BASE(20'hFFFF0)) raccoon_testregs
  (
    .CLK(clk_50),
    .RST(!fpga_reset_n),
    
    .TEST_PROGRESS(),
    .TEST_FAIL(),
    .TEST_PASS(),
  
    .RaccIn(RaccEvent2Test),
    .RaccOut(RaccTest2Ram)
  );

  sram #(.ADDR_MASK(20'hF0000), .ADDR_BASE(20'h00000)) sram
  (
    .CLK(clk_50),
    .RST(!fpga_reset_n),

    .RaccIn(RaccTest2Ram),
    .RaccOut(RaccRam2Core)
  );
  
endmodule
