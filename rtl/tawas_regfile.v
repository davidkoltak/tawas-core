
//
// Tawas Register File:
//
// This module contains the register file (16 x 32-bit registers) and
// all the read/write muxing logic.
//
// by
//   David M. Koltak  02/11/2016
//

module tawas_regfile
(
  input CLK,
  input RST,

  input PC_STORE,
  input [3:0] PC_STORE_REG,
  input [31:0] PC,

  input [3:0] PC_LOAD_REG,
  output [31:0] PC_RTN,

  input [3:0] AU_RA_SEL,
  output [31:0] AU_RA,
  input [3:0] AU_RB_SEL,
  output [31:0] AU_RB,

  input AU_RD_VLD,
  input [3:0] AU_RD_SEL,
  input [31:0] AU_RD,

  input [3:0] LS_PTR_REG,
  output [31:0] LS_PTR,

  input [3:0] LS_STORE_SEL,
  output [31:0] LS_STORE_DATA,

  input LS_LOAD_VLD,
  input [3:0] LS_LOAD_SEL,
  input [31:0] LS_LOAD_DATA 
);
 
endmodule
 
