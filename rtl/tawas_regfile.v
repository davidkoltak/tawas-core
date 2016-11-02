
//
// Tawas Register File:
//
// This module contains the register file (16 x 32-bit registers) and
// all the read/write muxing logic.
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

module tawas_regfile
(
  input CLK,
  input RST,

  input [1:0] SLICE,
    
  input PC_STORE,
  input [23:0] PC,
  output [23:0] PC_RTN,

  input RF_IMM_VLD,
  input [2:0] RF_IMM_SEL,
  input [31:0] RF_IMM,
  
  input [2:0] AU_RA_SEL,
  output [31:0] AU_RA,
  
  input [2:0] AU_RB_SEL,
  output [31:0] AU_RB,

  input AU_RC_VLD,
  input [2:0] AU_RC_SEL,
  input [31:0] AU_RC,

  input [2:0] LS_PTR_SEL,
  output [31:0] LS_PTR,

  input [2:0] LS_STORE_SEL,
  output [31:0] LS_STORE,

  input LS_PTR_UPD_VLD,
  input [2:0] LS_PTR_UPD_SEL,
  input [31:0] LS_PTR_UPD,
  
  input LS_LOAD_VLD,
  input [2:0] LS_LOAD_SEL,
  input [31:0] LS_LOAD,
  
  input RACCOON_LOAD_VLD,
  input [1:0] RACCOON_LOAD_SLICE,
  input [2:0] RACCOON_LOAD_SEL,
  input [31:0] RACCOON_LOAD
);

  reg [31:0] regfile_0[7:0];
  reg [31:0] regfile_0_nxt[7:0];
  reg [31:0] regfile_1[7:0];
  reg [31:0] regfile_1_nxt[7:0];
  reg [31:0] regfile_2[7:0];
  reg [31:0] regfile_2_nxt[7:0];
  reg [31:0] regfile_3[7:0];
  reg [31:0] regfile_3_nxt[7:0];
  
  integer x;
  
  always @ *
  begin
    for (x = 0; x < 8; x = x + 1)
    begin
      regfile_0_nxt[x] = regfile_0[x];
      regfile_1_nxt[x] = regfile_1[x];
      regfile_2_nxt[x] = regfile_2[x];
      regfile_3_nxt[x] = regfile_3[x];
    end
    
    if (RACCOON_LOAD_VLD)
      case (RACCOON_LOAD_SLICE[1:0])
      2'd0: regfile_0_nxt[RACCOON_LOAD_SEL] = RACCOON_LOAD;
      2'd1: regfile_1_nxt[RACCOON_LOAD_SEL] = RACCOON_LOAD;
      2'd2: regfile_2_nxt[RACCOON_LOAD_SEL] = RACCOON_LOAD;
      default: regfile_3_nxt[RACCOON_LOAD_SEL] = RACCOON_LOAD;
      endcase
            
    case (SLICE[1:0])
    2'd0:
    begin
      if (PC_STORE)
        regfile_3_nxt[6] = {8'd0, PC};
        
      if (RF_IMM_VLD)
        regfile_3_nxt[RF_IMM_SEL] = RF_IMM;
    
      if (AU_RC_VLD)
        regfile_1_nxt[AU_RC_SEL] = AU_RC;
        
      if (LS_PTR_UPD_VLD)
        regfile_2_nxt[LS_PTR_UPD_SEL] = LS_PTR_UPD;
    
      if (LS_LOAD_VLD)
        regfile_0_nxt[LS_LOAD_SEL] = LS_LOAD;
    end
    2'd1:
    begin
      if (PC_STORE)
        regfile_0_nxt[6] = {8'd0, PC};
        
      if (RF_IMM_VLD)
        regfile_0_nxt[RF_IMM_SEL] = RF_IMM;
    
      if (AU_RC_VLD)
        regfile_2_nxt[AU_RC_SEL] = AU_RC;
        
      if (LS_PTR_UPD_VLD)
        regfile_3_nxt[LS_PTR_UPD_SEL] = LS_PTR_UPD;
    
      if (LS_LOAD_VLD)
        regfile_1_nxt[LS_LOAD_SEL] = LS_LOAD;
    end
    2'd2:
    begin
      if (PC_STORE)
        regfile_1_nxt[6] = {8'd0, PC};
        
      if (RF_IMM_VLD)
        regfile_1_nxt[RF_IMM_SEL] = RF_IMM;
    
      if (AU_RC_VLD)
        regfile_3_nxt[AU_RC_SEL] = AU_RC;
        
      if (LS_PTR_UPD_VLD)
        regfile_0_nxt[LS_PTR_UPD_SEL] = LS_PTR_UPD;
    
      if (LS_LOAD_VLD)
        regfile_2_nxt[LS_LOAD_SEL] = LS_LOAD;
    end
    default:
    begin
      if (PC_STORE)
        regfile_2_nxt[6] = {8'd0, PC};
        
      if (RF_IMM_VLD)
        regfile_2_nxt[RF_IMM_SEL] = RF_IMM;
    
      if (AU_RC_VLD)
        regfile_0_nxt[AU_RC_SEL] = AU_RC;
        
      if (LS_PTR_UPD_VLD)
        regfile_1_nxt[LS_PTR_UPD_SEL] = LS_PTR_UPD;
    
      if (LS_LOAD_VLD)
        regfile_3_nxt[LS_LOAD_SEL] = LS_LOAD;
    end
    endcase
  end
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      for (x = 0; x < 8; x = x + 1)
      begin
        regfile_0[x] <= 32'd0;
        regfile_1[x] <= 32'd0;
        regfile_2[x] <= 32'd0;
        regfile_3[x] <= 32'd0;
      end
    else
      for (x = 0; x < 8; x = x + 1)
      begin
        regfile_0[x] <= regfile_0_nxt[x];
        regfile_1[x] <= regfile_1_nxt[x];
        regfile_2[x] <= regfile_2_nxt[x];
        regfile_3[x] <= regfile_3_nxt[x];
      end

  reg [31:0] pc_out;
  reg [31:0] ra_out;
  reg [31:0] rb_out;
  reg [31:0] ptr_out;
  reg [31:0] st_out;
  
  always @ *
    case (SLICE[1:0])
    2'd0:
    begin
      pc_out = regfile_3[6];
      ra_out = regfile_3[AU_RA_SEL];
      rb_out = regfile_3[AU_RB_SEL];
      ptr_out = regfile_3[LS_PTR_SEL];
      st_out = regfile_3[LS_STORE_SEL];
    end
    2'd1:
    begin
      pc_out = regfile_0[6];
      ra_out = regfile_0[AU_RA_SEL];
      rb_out = regfile_0[AU_RB_SEL];
      ptr_out = regfile_0[LS_PTR_SEL];
      st_out = regfile_0[LS_STORE_SEL];
    end
    2'd2:
    begin
      pc_out = regfile_1[6];
      ra_out = regfile_1[AU_RA_SEL];
      rb_out = regfile_1[AU_RB_SEL];
      ptr_out = regfile_1[LS_PTR_SEL];
      st_out = regfile_1[LS_STORE_SEL];
    end
    default:
    begin
      pc_out = regfile_2[6];
      ra_out = regfile_2[AU_RA_SEL];
      rb_out = regfile_2[AU_RB_SEL];
      ptr_out = regfile_2[LS_PTR_SEL];
      st_out = regfile_2[LS_STORE_SEL];
    end
    endcase
  
  assign PC_RTN = pc_out;
  assign AU_RA = ra_out;  
  assign AU_RB = rb_out;
  
  assign LS_PTR = ptr_out; 
  assign LS_STORE = st_out; 

  //
  // wires for simulation only... provides visibility with waveform viewers that cannot read arrays
  //
  
  wire [31:0] s0_r0;
  wire [31:0] s0_r1;
  wire [31:0] s0_r2;
  wire [31:0] s0_r3;
  wire [31:0] s0_r4;
  wire [31:0] s0_r5;
  wire [31:0] s0_r6;
  wire [31:0] s0_r7;
  
  wire [31:0] s1_r0;
  wire [31:0] s1_r1;
  wire [31:0] s1_r2;
  wire [31:0] s1_r3;
  wire [31:0] s1_r4;
  wire [31:0] s1_r5;
  wire [31:0] s1_r6;
  wire [31:0] s1_r7;
  
  wire [31:0] s2_r0;
  wire [31:0] s2_r1;
  wire [31:0] s2_r2;
  wire [31:0] s2_r3;
  wire [31:0] s2_r4;
  wire [31:0] s2_r5;
  wire [31:0] s2_r6;
  wire [31:0] s2_r7;
  
  wire [31:0] s3_r0;
  wire [31:0] s3_r1;
  wire [31:0] s3_r2;
  wire [31:0] s3_r3;
  wire [31:0] s3_r4;
  wire [31:0] s3_r5;
  wire [31:0] s3_r6;
  wire [31:0] s3_r7;
  
  assign s0_r0 = regfile_0[0];
  assign s0_r1 = regfile_0[1];
  assign s0_r2 = regfile_0[2];
  assign s0_r3 = regfile_0[3];
  assign s0_r4 = regfile_0[4];
  assign s0_r5 = regfile_0[5];
  assign s0_r6 = regfile_0[6];
  assign s0_r7 = regfile_0[7];
  
  assign s1_r0 = regfile_1[0];
  assign s1_r1 = regfile_1[1];
  assign s1_r2 = regfile_1[2];
  assign s1_r3 = regfile_1[3];
  assign s1_r4 = regfile_1[4];
  assign s1_r5 = regfile_1[5];
  assign s1_r6 = regfile_1[6];
  assign s1_r7 = regfile_1[7];
  
  assign s2_r0 = regfile_2[0];
  assign s2_r1 = regfile_2[1];
  assign s2_r2 = regfile_2[2];
  assign s2_r3 = regfile_2[3];
  assign s2_r4 = regfile_2[4];
  assign s2_r5 = regfile_2[5];
  assign s2_r6 = regfile_2[6];
  assign s2_r7 = regfile_2[7];
  
  assign s3_r0 = regfile_3[0];
  assign s3_r1 = regfile_3[1];
  assign s3_r2 = regfile_3[2];
  assign s3_r3 = regfile_3[3];
  assign s3_r4 = regfile_3[4];
  assign s3_r5 = regfile_3[5];
  assign s3_r6 = regfile_3[6];
  assign s3_r7 = regfile_3[7];
  
endmodule
 
