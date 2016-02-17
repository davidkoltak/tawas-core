
module dram
(
  input CLK,
  
  input [31:0] ADDR,
  input CS,
  input WR,
  input [3:0] MASK,
  input [31:0] DIN,
  output [31:0] DOUT
);

  parameter DRAM_DATA_FILE = "./dram.hex";
  
  reg [31:0] data_array[(1024 * 16)-1:0];
  reg [31:0] data_out;
  wire [31:0] bitmask;
  
  initial
  begin
    $readmemh(DRAM_DATA_FILE, data_array);
  end

  assign bitmask = {{8{MASK[3]}}, {8{MASK[2]}}, {8{MASK[1]}}, {8{MASK[0]}}};
  
  always @ (posedge CLK)
    if (CS && WR)
      data_array[ADDR[31:2]] <= (data_array[ADDR[31:2]] & ~bitmask) | (DIN & bitmask);
    
  always @ (posedge CLK)
    if (CS)
      data_out <= data_array[ADDR[31:2]];
  
  assign DOUT = data_out;
  
endmodule
