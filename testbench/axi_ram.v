
module axi_ram
(
  input CLK,
  
  input [31:0] ADDR,
  input CS,
  input WR,
  input [63:0] MASK,
  input [63:0] DIN,
  output [63:0] DOUT
);
  
  reg [63:0] data_array[(1024 * 8)-1:0];
  reg [63:0] data_out;
  
  always @ (posedge CLK)
    if (CS && WR)
      data_array[ADDR[15:3]] <= (data_array[ADDR[15:3]] & ~MASK) | (DIN & MASK);
    
  always @ (posedge CLK)
    if (CS)
      data_out <= data_array[ADDR[15:3]];
  
  assign DOUT = data_out;
  
endmodule
