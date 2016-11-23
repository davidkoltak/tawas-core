
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

  input [1:0] SLICE,
  output [7:0] AU_FLAGS,

  input AU_OP_VLD,
  input [14:0] AU_OP,

  input AU_IMM_VLD,
  input [27:0] AU_IMM,
  
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
  reg [27:0] imm_hold_2;
  reg [27:0] imm_hold_3;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      imm_hold_0 <= 28'd0;
    else if (AU_IMM_VLD && (SLICE == 2'd0))
      imm_hold_0 <= AU_IMM;

  always @ (posedge CLK or posedge RST)
    if (RST)
      imm_hold_1 <= 28'd0;
    else if (AU_IMM_VLD && (SLICE == 2'd1))
      imm_hold_1 <= AU_IMM;

  always @ (posedge CLK or posedge RST)
    if (RST)
      imm_hold_2 <= 28'd0;
    else if (AU_IMM_VLD && (SLICE == 2'd2))
      imm_hold_2 <= AU_IMM;

  always @ (posedge CLK or posedge RST)
    if (RST)
      imm_hold_3 <= 28'd0;
    else if (AU_IMM_VLD && (SLICE == 2'd3))
      imm_hold_3 <= AU_IMM;

  //
  // OP DECODE
  //
  
  wire imm_vld;
  wire [31:0] imm;
  wire [4:0] op_mux;
  wire [2:0] reg_c_sel;
  
  assign imm_vld = AU_OP[14];
  assign imm[31:4] = (SLICE == 2'd3) ? imm_hold_3 :
                     (SLICE == 2'd2) ? imm_hold_2 :
                     (SLICE == 2'd1) ? imm_hold_1 : imm_hold_0;
  assign imm[3] = AU_OP[13];
  assign imm[2:0] = AU_OP[5:3];
  
  assign op_mux = AU_OP[13:9] & ((imm_vld) ? 5'h0F : 5'h1F);
  
  assign AU_RA_SEL = AU_OP[8:6];
  assign AU_RB_SEL = AU_OP[5:3];
  assign reg_c_sel = AU_OP[2:0];
    
  //
  // REGISTER STAGE
  //
  
  reg [31:0] reg_a;
  reg [31:0] reg_b;
  reg [4:0] op_mux_d1;
  reg [4:0] op_mux_d2;
  reg [2:0] reg_a_as_imm;
  reg [2:0] reg_b_as_imm;
  reg [2:0] reg_c_sel_d1;
  reg [2:0] reg_c_sel_d2;
  
  reg au_result_vld;
  reg au_result_vld_d1;
  
  always @ (posedge CLK)
    if (AU_OP_VLD)
    begin
      reg_a <= AU_RA;
      reg_b <= (imm_vld) ? imm : AU_RB;
      reg_a_as_imm <= AU_OP[8:6];
      reg_b_as_imm <= AU_OP[5:3];
    end
  
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      au_result_vld <= 1'b0;
      au_result_vld_d1 <= 1'b0;
      op_mux_d1 <= 5'd0;
      op_mux_d2 <= 5'd0;
      reg_c_sel_d1 <= 3'd0;
      reg_c_sel_d2 <= 3'd0;
    end
    else
    begin
      au_result_vld <= AU_OP_VLD;
      au_result_vld_d1 <= au_result_vld;
      op_mux_d1 <= op_mux;
      op_mux_d2 <= op_mux_d1;
      reg_c_sel_d1 <= reg_c_sel;
      reg_c_sel_d2 <= reg_c_sel_d1;
    end
  
  //
  // Generate AU results
  //
  
  reg [32:0] add_value;
  reg [32:0] add_sub;
  reg [32:0] add_result;
  reg [31:0] au_result;
  reg [31:0] bit_mask;
  
  always @ *
  begin
    add_value = (op_mux_d1[4]) ? {{30{1'b0}}, reg_b_as_imm} : {reg_b[31], reg_b};
    add_sub = (op_mux_d1[0]) ? add_value : (~add_value) + 33'd1;
    add_result = {reg_a[31], reg_a} + add_sub;
    bit_mask = (1 << reg_b_as_imm);
  end
  
  always @ (posedge CLK)
  begin
    if (op_mux_d1[4:3] == 2'b11)
      au_result <= {{23{op_mux_d1[2]}}, op_mux_d1[2:0], reg_a_as_imm[2:0], reg_b_as_imm[2:0]};
    else
      case (op_mux_d1)
      5'h00: au_result <= reg_a | reg_b;
      5'h01: au_result <= reg_a ^ reg_b;
      5'h02: au_result <= add_result[31:0]; // a - b : compare (squash write-back)
      5'h03: au_result <= add_result[31:0]; // a + b
      5'h04: au_result <= add_result[31:0]; // a - b
      5'h05: au_result <= reg_a & reg_b;
      5'h07: au_result <= 32'hFFFFFBAD;
      5'h08: au_result <= 32'hFFFFFBAD;
      
      5'h09: au_result <= 32'hFFFFFBAD;
      5'h0A: au_result <= 32'hFFFFFBAD;
      5'h0B: au_result <= 32'hFFFFFBAD;
      5'h0C: au_result <= 32'hFFFFFBAD;
      5'h0D: au_result <= 32'hFFFFFBAD;
      5'h0E: au_result <= 32'hFFFFFBAD;
      5'h0F: au_result <= 32'hFFFFFBAD;
      
      5'h10: au_result <= reg_a | bit_mask;
      5'h11: au_result <= reg_a & ~bit_mask;
      5'h12: au_result <= add_result[31:0]; // a - imm_b
      5'h13: au_result <= add_result[31:0]; // a + imm_b

      5'h14: au_result <= (reg_a << reg_b_as_imm);
      5'h15: au_result <= (reg_a >> reg_b_as_imm);
      5'h16: au_result <= (reg_a >>> reg_b_as_imm);

      5'h17: au_result <= (reg_b_as_imm[1:0] == 2'b00) ? {32{reg_a[0]}}:
                          (reg_b_as_imm[1:0] == 2'b01) ? {{24{reg_a[7]}}, reg_a[7:0]} :
                          (reg_b_as_imm[1:0] == 2'b10) ? {{16{reg_a[15]}}, reg_a[15:0]} :
                          (reg_b_as_imm[1:0] == 2'b11) ? {{8{reg_a[23]}}, reg_a[23:0]} : reg_a;

      default: au_result <= 32'd0;
      endcase
  end
  
  assign AU_RC_VLD = au_result_vld_d1 && (op_mux_d2 != 5'h02);
  assign AU_RC_SEL = reg_c_sel_d2;
  assign AU_RC = au_result;
  
  //
  // Select Flags
  //
  
  reg [7:0] result_flags;
  reg [7:0] s0_flags;
  reg [7:0] s1_flags;
  reg [7:0] s2_flags;
  reg [7:0] s3_flags;
  
  always @ *
  begin
    case (SLICE[1:0])
    2'd0: result_flags = s1_flags;
    2'd1: result_flags = s2_flags;
    2'd2: result_flags = s3_flags;
    default: result_flags = s0_flags;
    endcase
    
    result_flags[0] = (au_result == 32'd0);                               // zero
    result_flags[1] = au_result[31];                                      // neg
    result_flags[2] = add_result[32] ^ add_result[31];                    // sovfl
    result_flags[3] = (reg_a[31] && !add_sub[32] && !add_result[32]) ||   // uovfl
                      (!reg_a[31] && add_sub[32] && add_result[31]);
  end
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      s0_flags <= 8'd0;
    else if (au_result_vld_d1 && (SLICE == 2'd3))
      s0_flags <= result_flags;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      s1_flags <= 8'd0;
    else if (au_result_vld_d1 && (SLICE == 2'd0))
      s1_flags <= result_flags;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      s2_flags <= 8'd0;
    else if (au_result_vld_d1 && (SLICE == 2'd1))
      s2_flags <= result_flags;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      s3_flags <= 8'd0;
    else if (au_result_vld_d1 && (SLICE == 2'd2))
      s3_flags <= result_flags;
      
  assign AU_FLAGS = (SLICE == 2'd3) ? s2_flags :
                    (SLICE == 2'd2) ? s1_flags :
                    (SLICE == 2'd1) ? s0_flags : s3_flags;
  
endmodule
