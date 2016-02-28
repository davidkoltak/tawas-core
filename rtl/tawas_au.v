
//
// Tawas Arithmetic Unit:
//
// Perform arithmetic on registers.
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

module tawas_au
(
  input CLK,
  input RST,

  input SLICE,
  output [15:0] AU_FLAGS,

  input AU_OP_VLD,
  input [14:0] AU_OP,

  input AU_OP_IMM_VLD,
  input [27:0] AU_OP_IMM,
  
  output [2:0] AU_RA_SEL,
  input [31:0] AU_RA,
  
  output [2:0] AU_RB_SEL,
  input [31:0] AU_RB,
  
  output AU_RC_VLD,
  output [2:0] AU_RC_SEL,
  output [31:0] AU_RC
);
  
  assign AU_FLAGS = 16'h0001;
  
  assign AU_RA_SEL = AU_OP_RA;
  assign AU_RB_SEL = AU_OP_RB;
  
  reg [31:0] reg_a;
  reg [31:0] reg_b;
  reg [5:0] op_d1;
  reg [3:0] reg_a_as_imm;
  reg [3:0] reg_d_sel;
  
  reg au_result_vld;
  reg [31:0] au_result;
  
  always @ (posedge CLK)
    if (AU_OP_VLD)
    begin
      reg_a <= (AU_OP_IMM_VLD) ? AU_OP_IMM : AU_RA;
      reg_b <= AU_RB;
      op_d1 <= AU_OP;
      reg_a_as_imm <= AU_OP_RA;
      reg_d_sel <= AU_OP_RB;
    end
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      au_result_vld <= 1'b0;
    else
      au_result_vld <= AU_OP_VLD;
    
  always @ *
    case (op_d1)
    6'h00: au_result = reg_a;
    6'h01: au_result = ~reg_a;
    6'h02: au_result = reg_b + {{28{1'b0}}, reg_a_as_imm[3:0]};
    6'h03: au_result = reg_b - {{28{1'b0}}, reg_a_as_imm[3:0]};
    
    6'h04: au_result = (reg_b << reg_a_as_imm[3:0]);
    6'h05: au_result = (reg_b >> reg_a_as_imm[3:0]);
    6'h06: au_result = (reg_b >>> reg_a_as_imm[3:0]);
    6'h07: au_result = (reg_a_as_imm[1:0] == 2'b00) ? {{24{reg_b[7]}}, reg_b[7:0]} :
                       (reg_a_as_imm[1:0] == 2'b01) ? {{16{reg_b[15]}}, reg_b[15:0]} : reg_b;
    
    6'h08: au_result = reg_b + reg_a;
    6'h09: au_result = reg_b - reg_a;
    6'h0A: au_result = reg_b & reg_a;
    6'h0B: au_result = reg_b | reg_a;
    6'h0C: au_result = reg_b ^ reg_a;
    
    default: ;
    endcase
  
  assign AU_RD_VLD = au_result_vld;
  assign AU_RD_SEL = reg_d_sel;
  assign AU_RD = au_result;
  
endmodule
