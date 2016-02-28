
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

  input SLICE,
    
  input PC_STORE,
  input [23:0] PC,
  output [23:0] PC_RTN,

  input EC_STORE,
  input [31:0] EC,
  
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
  input [31:0] LS_LOAD
);

  reg [31:0] regfile_0[7:0];
  reg [31:0] regfile_0_nxt[7:0];
  reg [31:0] regfile_1[7:0];
  reg [31:0] regfile_1_nxt[7:0];
  
  integer x;
  
  always @ *
  begin
    for (x = 0; x < 8; x = x + 1)
    begin
      regfile_0_nxt[x] = regfile_0[x];
      regfile_1_nxt[x] = regfile_1[x];
    end
    
    if (PC_STORE)
    begin
      regfile_0_nxt[7] = PC;
      regfile_1_nxt[7] = PC;
    end
    
    if (EC_STORE)
    begin
      regfile_0_nxt[0] = EC;
      regfile_1_nxt[0] = EC;
    end
    
    if (AU_RC_VLD)
    begin
      regfile_0_nxt[AU_RC_SEL] = AU_RC;
      regfile_1_nxt[AU_RC_SEL] = AU_RC;
    end
    
    if (LS_PTR_UPD_VLD)
    begin
      regfile_0_nxt[LS_PTR_UPD_SEL] = LS_PTR_UPD;
      regfile_1_nxt[LS_PTR_UPD_SEL] = LS_PTR_UPD;
    end
    
    if (LS_LOAD_VLD)
    begin
      regfile_0_nxt[LS_LOAD_SEL] = LS_LOAD;
      regfile_1_nxt[LS_LOAD_SEL] = LS_LOAD;
    end
  end
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      for (x = 0; x < 8; x = x + 1)
        regfile_0[x] <= 32'd0;
    else if (SLICE == 1'b1)
      for (x = 0; x < 8; x = x + 1)
        regfile_0[x] <= regfile_0_nxt[x];
      
  always @ (posedge CLK or posedge RST)
    if (RST)
      for (x = 0; x < 8; x = x + 1)
        regfile_1[x] <= 32'd0;
    else if (SLICE == 1'b0)
      for (x = 0; x < 8; x = x + 1)
        regfile_1[x] <= regfile_1_nxt[x];

  assign PC_RTN = (SLICE) ? regfile_1[15] : regfile_0[15];
  
  assign AU_RA = (SLICE) ? regfile_1[AU_RA_SEL] : regfile_0[AU_RA_SEL];  
  assign AU_RB = (SLICE) ? regfile_1[AU_RB_SEL] : regfile_0[AU_RB_SEL];
  
  assign LS_PTR = (SLICE) ? regfile_1[LS_PTR_SEL] : regfile_0[LS_PTR_SEL]; 
  assign LS_STORE = (SLICE) ? regfile_1[LS_STORE_SEL] : regfile_0[LS_STORE_SEL]; 

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
  
endmodule
 
