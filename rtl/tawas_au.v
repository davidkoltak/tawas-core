
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
  
  //
  // Immediate Data holding registers
  //
  
  reg [27:0] imm_hold_0;
  reg [27:0] imm_hold_1;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      imm_hold_0 <= 28'd0;
    else if (AU_OP_IMM_VLD && (!SLICE))
      imm_hold_0 <= AU_OP_IMM;

  always @ (posedge CLK or posedge RST)
    if (RST)
      imm_hold_1 <= 28'd0;
    else if (AU_OP_IMM_VLD && SLICE)
      imm_hold_1 <= AU_OP_IMM;

  //
  // OP DECODE
  //
  
  wire imm_vld;
  wire [31:0] imm;
  wire [4:0] op_mux;
  wire [2:0] reg_c_sel;
  
  assign imm_vld = AU_OP[14];
  assign imm[31:4] = (SLICE) ? imm_hold_1 : imm_hold_0;
  assign imm[3] = AU_OP[13];
  assign imm[2:0] = AU_OP[5:3];
  
  assign op_mux = AU_OP[13:9] & ((au_imm_vld) ? 5'h0F : 5'h1F);
  
  assign AU_RA_SEL = AU_OP[8:6];
  assign AU_RB_SEL = AU_OP[5:3];
  assign reg_c_sel = AU_OP[2:0];
    
  //
  // REGISTER STAGE
  //
  
  reg [31:0] reg_a;
  reg [31:0] reg_b;
  reg [5:0] op_mux_d1;
  reg [3:0] reg_b_as_imm;
  reg [3:0] reg_c_sel_d1;
  
  reg au_result_vld;
  
  always @ (posedge CLK)
    if (AU_OP_VLD)
    begin
      reg_a <= AU_RA;
      reg_b <= (imm_vld) ? imm : AU_RB;
      reg_b_as_imm <= AU_OP[5:3];
      op_mux_d1 <= op_mux;
      reg_c_sel_d1 <= reg_c_sel;
    end
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      au_result_vld <= 1'b0;
    else
      au_result_vld <= AU_OP_VLD;
  
  //
  // Generate AU results
  //
  
  reg [31:0] au_result;
  wire [31:0] cheap_imm;
  
  assign cheap_imm = {{28{1'b0}}, {1'b0, reg_b_as_imm[2:0]} + 4'd1};
  
  always @ *
    case (op_mux_d1)
    6'h00: au_result = reg_b;
    6'h01: au_result = ~reg_b;
    6'h02: au_result = reg_a + cheap_imm;
    6'h03: au_result = reg_a - cheap_imm;
    
    6'h04: au_result = (reg_a << reg_b_as_imm[2:0]);
    6'h05: au_result = (reg_a >> reg_b_as_imm[2:0]);
    6'h06: au_result = (reg_a >>> reg_b_as_imm[2:0]);
    6'h07: au_result = (reg_b_as_imm[1:0] == 2'b00) ? {{24{reg_a[7]}}, reg_a[7:0]} :
                       (reg_b_as_imm[1:0] == 2'b01) ? {{16{reg_a[15]}}, reg_a[15:0]} : reg_a;
    
    6'h08: au_result = reg_a + reg_b;
    6'h09: au_result = reg_a - reg_b;
    6'h0A: au_result = reg_a & reg_b;
    6'h0B: au_result = reg_a | reg_b;
    6'h0C: au_result = reg_a ^ reg_b;
    
    default: ;
    endcase
  
  assign AU_RC_VLD = au_result_vld;
  assign AU_RC_SEL = reg_c_sel_d1;
  assign AU_RC = au_result;
  
  //
  // Select Flags
  //
  
  assign AU_FLAGS = 16'h0001;
  
endmodule
