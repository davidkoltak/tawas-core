//
// RCN bus module to handle event flag processing.
//
// by
//     David Koltak  11/22/2016
//
// This module provides four registers with 32 single bit flags per register.
// Writing a value of (0-31) to a register sets a flag. Reading a register
// returns the flag bit values and clears it.
//
// Using a bus ID of 8'hFF will cause this module to take the transaction off
// the bus without acknowledge.  This is used for slave only peripherals that
// are not assigned a bus ID.
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

module rcn_event
(
  CLK,
  RST,

  EventPending,
  
  RCN_IN,
  RCN_OUT
);
  parameter ADDR_MASK = 20'hFFFE0;
  parameter ADDR_BASE = 20'hFFFE0;
  
  input CLK;
  input RST;

  output reg [3:0] EventPending;
  
  input [63:0] RCN_IN;
  output [63:0] RCN_OUT;

  reg [63:0] din;
  reg [63:0] din_d1;
  reg [63:0] dout;
  
  assign RCN_OUT = dout;
  
  wire addr_match = (din[63:62] == 2'b11) && (({din[49:32], 2'b00} & ADDR_MASK) == (ADDR_BASE & ADDR_MASK));
  reg addr_match_d1;
  
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
      din <= RCN_IN;
      addr_match_d1 <= addr_match;
      din_d1 <= din;
      dout <= (addr_match_d1) ? (din_d1[61:54] == 8'hFF) ? 64'd0 : {2'b10, din_d1[61:32], event_out} : din_d1[63:0];
    end
  
  reg [31:0] event_0;
  reg [31:0] event_1;
  reg [31:0] event_2;
  reg [31:0] event_3;
  reg [31:0] event_out;
  
  reg [31:0] mask_0;
  reg [31:0] mask_1;
  reg [31:0] mask_2;
  reg [31:0] mask_3;
  reg [31:0] bit_mask;
  
  always @ *
    if (|din[31:6])
      bit_mask = 0;
    else
      bit_mask = (1 << din[5:0]);

  always @ (posedge CLK)
    EventPending <= {|(event_3 & ~mask_3), |(event_2 & ~mask_2), |(event_1 & ~mask_1), |(event_0 & ~mask_0)};
    
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      event_0 <= 32'd0;
      event_1 <= 32'd0;
      event_2 <= 32'd0;
      event_3 <= 32'd0;
      event_out <= 32'd0;
      mask_0 <= 32'd0;
      mask_1 <= 32'd0;
      mask_2 <= 32'd0;
      mask_3 <= 32'd0;
    end
    else if (addr_match)
    begin 
      case (din[34:32])
      3'd0: event_out <= event_0;
      3'd1: event_out <= event_1;
      3'd2: event_out <= event_2;
      3'd3: event_out <= event_3;
      3'd4: event_out <= mask_0;
      3'd5: event_out <= mask_1;
      3'd6: event_out <= mask_2;
      default: event_out <= mask_3;
      endcase
        
      if (din[53:50] == 4'b1111)
      begin
        case (din[34:32])
        3'd0: event_0 <= event_0 | bit_mask;
        3'd1: event_1 <= event_1 | bit_mask;
        3'd2: event_2 <= event_2 | bit_mask;
        3'd3: event_3 <= event_3 | bit_mask;
        3'd4: mask_0 <= din[31:0];
        3'd5: mask_1 <= din[31:0];
        3'd6: mask_2 <= din[31:0];
        default: mask_3 <= din[31:0];
        endcase
      end
      else if (din[53:50] == 4'b0000)
      begin
        case (din[34:32])
        3'd0: event_0 <= 32'd0;
        3'd1: event_1 <= 32'd0;
        3'd2: event_2 <= 32'd0;
        3'd3: event_3 <= 32'd0;
        default: ;
        endcase
      end
    end
      
endmodule
