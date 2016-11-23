//
// Raccoon bus module to handle event flag processing.
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

module raccoon_event
(
  CLK,
  RST,

  RaccIn,
  RaccOut
);
  parameter ADDR_MASK = 32'hFFFFFFF0;
  parameter ADDR_BASE = 32'hFFFFFFE0;
  
  input CLK;
  input RST;

  input [79:0] RaccIn;
  output [79:0] RaccOut;

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
      dout <= (addr_match_d1) ? (din_d1[75:68] == 8'hFF) ? 80'd0 : {din_d1[79:78], 2'b10, din_d1[75:64], event_out[31:0], din_d1[31:0]} : din_d1[79:0];
    end
  
  reg [31:0] event_0;
  reg [31:0] event_1;
  reg [31:0] event_2;
  reg [31:0] event_3;
  reg [31:0] event_out;
  reg [31:0] bit_mask;
  
  always @ *
    if (|din[63:37])
      bit_mask = 0;
    else
      bit_mask = (1 << din[36:32]);
    
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      event_0 <= 32'd0;
      event_1 <= 32'd0;
      event_2 <= 32'd0;
      event_3 <= 32'd0;
      event_out <= 32'd0;
    end
    else if (addr_match && &din[67:64])
    begin 
      case (din[3:2])
      2'd0: event_out <= event_0;
      2'd1: event_out <= event_1;
      2'd2: event_out <= event_2;
      default: event_out <= event_3;
      endcase
        
      if (din[78])
      begin
        case (din[3:2])
        2'd0: event_0 <= event_0 | bit_mask;
        2'd1: event_1 <= event_1 | bit_mask;
        2'd2: event_2 <= event_2 | bit_mask;
        default: event_3 <= event_3 | bit_mask;
        endcase
      end
      else
      begin
        case (din[3:2])
        2'd0: event_0 <= 32'd0;
        2'd1: event_1 <= 32'd0;
        2'd2: event_2 <= 32'd0;
        default: event_3 <= 32'd0;
        endcase
      end
    end
      
endmodule
