
//
// Tawas Arithmetic Unit:
//
// Perform arithmetic on registers.
//
// by
//   David M. Koltak  02/11/2016
//

module tawas_au
(
  input CLK,
  input RST,

  input [15:0] AU_FLAGS,

  input AU_OP_VLD,
  input [5:0] AU_OP,
  input [3:0] AU_OP_RA,
  input [3:0] AU_OP_RB,

  input AU_OP_IMM_VLD,
  input [31:0] AU_OP_IMM,
  
  output [3:0] AU_RA_SEL,
  input [31:0] AU_RA,
  output [3:0] AU_RB_SEL,
  input [31:0] AU_RB,
  
  output AU_RD_VLD,
  output [3:0] AU_RD_SEL,
  output [31:0] AU_RD
);
  
  assign AU_FLAGS = 16'h0001;
  
endmodule
