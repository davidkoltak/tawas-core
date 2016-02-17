
//
// Tawas Load/Store:
//
// Perform load/store operations between the data bus and register file.
//
// by
//   David M. Koltak  02/11/2016
//

module tawas_ls
(
  input CLK,
  input RST,

  output [31:0] DADDR,
  output DCS,
  output DWR,
  output [3:0] DMASK,
  output [31:0] DOUT,
  input [31:0] DIN,

  input LS_OP_VLD,
  input LS_OP_STORE,
  input [1:0] LS_OP_TYPE,
  input [3:0] LS_OP_OFFSET,
  input [3:0] LS_OP_REG,

  input [31:0] LS_PTR,
  input [31:0] LS_STORE_DATA,

  output LS_LOAD_VLD,
  output [3:0] LS_LOAD_SEL,
  output [31:0] LS_LOAD_DATA
);

endmodule
  
