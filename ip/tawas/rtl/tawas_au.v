
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
  
  output [3:0] AU_RA_SEL,
  input [31:0] AU_RA,
  
  output [3:0] AU_RB_SEL,
  input [31:0] AU_RB,
  
  output AU_RC_VLD,
  output [3:0] AU_RC_SEL,
  output [31:0] AU_RC
);

  //
  // OP DECODE
  //
  
  wire tworeg_vld;
  wire [3:0] tworeg_cmd;
  wire [3:0] reg_c_sel;
  
  wire bitop_vld;
  wire [2:0] bitop_cmd;
  wire [4:0] bitop_sel;
  
  wire imm_vld;
  wire [1:0] imm_cmd;
  wire [31:0] imm;
  
  assign tworeg_vld = AU_OP_VLD && (AU_OP[14:13] == 2'b00);
  assign tworeg_cmd = (AU_OP[12]) ? {1'b0, AU_OP[11:9]} : AU_OP[11:8];
  
  assign bitop_vld = AU_OP_VLD && (AU_OP[14:12] == 3'b010);
  assign bitop_cmd = AU_OP[11:9];
  assign bitop_sel = AU_OP[8:4];
  
  assign imm_vld = AU_OP_VLD && (AU_OP[14] | (AU_OP[14:12] == 3'b011));
  assign imm_cmd = AU_OP[14:13];
  assign imm = (AU_OP[14]) ? {{23{AU_OP[12]}}, AU_OP[12:4]} : {{24{AU_OP[11]}}, AU_OP[11:4]};
  
  assign AU_RA_SEL = (AU_OP[14:12] == 3'b001) ? {1'b0, AU_OP[2:0]} : AU_OP[3:0];
  assign AU_RB_SEL = (AU_OP[14:12] == 3'b001) ? {1'b0, AU_OP[5:3]} : AU_OP[7:4];
  assign reg_c_sel = (AU_OP[14:12] == 3'b001) ? {1'b0, AU_OP[8:6]} : AU_OP[3:0];
    
  //
  // REGISTER STAGES
  //
  
  reg [31:0] reg_a_d1;
  reg [31:0] reg_b_d1;
  reg [3:0] tworeg_cmd_d1;
  reg [1:0] imm_cmd_d1;
  
  reg tworeg_vld_d1;
  reg bitop_vld_d1;
  reg imm_vld_d1;
  reg writeback_vld_d1;
  reg [3:0] reg_c_sel_d1;
  
  reg tworeg_vld_d2;
  reg bitop_vld_d2;
  reg imm_vld_d2;
  reg writeback_vld_d2;
  reg [3:0] reg_c_sel_d2;
  
  always @ (posedge CLK)
    if (AU_OP_VLD)
    begin
      reg_a_d1 <= AU_RA;
      reg_b_d1 <= (imm_vld) ? imm : (bitop_vld) ? {24'd0, bitop_cmd, bitop_sel} : AU_RB;
      tworeg_cmd_d1 <= tworeg_cmd;
      imm_cmd_d1 <= imm_cmd;  
    end

  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      tworeg_vld_d1 <= 1'b0;
      bitop_vld_d1 <= 1'b0;
      imm_vld_d1 <= 1'b0;
      writeback_vld_d1 <= 1'b0;
      reg_c_sel_d1 <= 4'd0;
      
      tworeg_vld_d2 <= 1'b0;
      bitop_vld_d2 <= 1'b0;
      imm_vld_d2 <= 1'b0;
      writeback_vld_d2 <= 1'b0;
      reg_c_sel_d2 <= 4'd0;
    end
    else
    begin
      tworeg_vld_d1 <= tworeg_vld;
      bitop_vld_d1 <= bitop_vld;
      imm_vld_d1 <= imm_vld;
      writeback_vld_d1 <= (tworeg_vld && (tworeg_cmd != 4'hB)) || (bitop_vld && (bitop_cmd != 3'd2)) || (imm_vld_d1 && (imm_cmd != 2'd2));
      reg_c_sel_d1 <= reg_c_sel;
      
      tworeg_vld_d2 <= tworeg_vld_d1;
      bitop_vld_d2 <= bitop_vld_d1;
      imm_vld_d2 <= imm_vld_d1;
      writeback_vld_d2 <= writeback_vld_d1;
      reg_c_sel_d2 <= reg_c_sel_d1;
    end
  
  //
  // Generate AU results
  //
  
  reg [32:0] tworeg_result;
  
  always @ (posedge CLK)
    if (tworeg_vld_d1)
      case (tworeg_cmd_d1)
      4'h0: tworeg_result <= {1'b0, reg_a_d1 | reg_b_d1};
      4'h1: tworeg_result <= {1'b0, reg_a_d1 & reg_b_d1};
      4'h2: tworeg_result <= {1'b0, reg_a_d1 ^ reg_b_d1};
      4'h3: tworeg_result <= {reg_a_d1[31], reg_a_d1} + {reg_b_d1[31], reg_b_d1};
      4'h4: tworeg_result <= {reg_a_d1[31], reg_a_d1} - {reg_b_d1[31], reg_b_d1};
      
      4'h8: tworeg_result <= {reg_b_d1[31], reg_b_d1};
      4'h9: tworeg_result <= ~{reg_b_d1[31], reg_b_d1};
      4'hA: tworeg_result <= 33'd1 + ~{reg_b_d1[31], reg_b_d1};
      4'hB: tworeg_result <= {reg_a_d1[31], reg_a_d1} - {reg_b_d1[31], reg_b_d1};
      
      default: tworeg_result <= 33'd0;
      endcase
    
  reg [32:0] bitop_result;
  wire [2:0] bitop_cmd_d1 = reg_b_d1[7:5];
  wire [4:0] bitop_sel_d1 = reg_b_d1[4:0];
  integer x;
  
  always @ (posedge CLK)
    if (bitop_vld_d1)
      case (bitop_cmd_d1)
      3'd0: bitop_result <= {1'b0, reg_a_d1 | (32'd1 << bitop_sel_d1)};
      3'd1: bitop_result <= {1'b0, reg_a_d1 & ~(32'd1 << bitop_sel_d1)};
      3'd2: bitop_result <= {1'b0, reg_a_d1 & (32'd1 << bitop_sel_d1)};
      
      3'd4: bitop_result <= ({1'b0, reg_a_d1} << bitop_sel_d1);
      3'd5: bitop_result <= ({1'b0, reg_a_d1} >> bitop_sel_d1);
      3'd6: bitop_result <= ({reg_a_d1[31], reg_a_d1} >>> bitop_sel_d1);
      3'd7: 
      begin
        for (x = 0; x < bitop_sel_d1; x = x + 1)
          bitop_result[x] = reg_a_d1[x];
        for (x = bitop_sel_d1; x < 33; x = x + 1)
           bitop_result[x] = reg_a_d1[bitop_sel_d1];
      end    
      default: bitop_result <= 33'd0;
      endcase    
    
  reg [32:0] imm_result;

  always @ (posedge CLK)
    if (imm_vld_d1)
      case (imm_cmd_d1)
      2'd1: imm_result <= {reg_a_d1[31], reg_a_d1} + {reg_b_d1[31], reg_b_d1};
      2'd2: imm_result <= {reg_a_d1[31], reg_a_d1} - {reg_b_d1[31], reg_b_d1};
      2'd3: imm_result <= {reg_b_d1[31], reg_b_d1};      
      default: imm_result <= 33'd0;
      endcase  
  
  //
  // Send result back to register file
  //
  
  wire au_result_vld = imm_vld_d2 | bitop_vld_d2 | tworeg_vld_d2;
  wire [32:0] au_result = (imm_vld_d2) ? imm_result : 
                          (bitop_vld_d2) ? bitop_result : tworeg_result;
  
  assign AU_RC_VLD = writeback_vld_d2;
  assign AU_RC_SEL = reg_c_sel_d2;
  assign AU_RC = au_result[31:0];
  
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
    result_flags[2] = au_result[32] ^ au_result[31];                      // ovfl
  end
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      s0_flags <= 8'd0;
    else if (au_result_vld && (SLICE == 2'd3))
      s0_flags <= result_flags;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      s1_flags <= 8'd0;
    else if (au_result_vld && (SLICE == 2'd0))
      s1_flags <= result_flags;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      s2_flags <= 8'd0;
    else if (au_result_vld && (SLICE == 2'd1))
      s2_flags <= result_flags;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      s3_flags <= 8'd0;
    else if (au_result_vld && (SLICE == 2'd2))
      s3_flags <= result_flags;
      
  assign AU_FLAGS = (SLICE == 2'd3) ? s2_flags :
                    (SLICE == 2'd2) ? s1_flags :
                    (SLICE == 2'd1) ? s0_flags : s3_flags;
  
endmodule
