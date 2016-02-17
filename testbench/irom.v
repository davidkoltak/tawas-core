
module irom
(
  input CLK,
  
  input [23:0] ADDR,
  input CS,
  output [31:0] DOUT
);

  parameter IROM_DATA_FILE = "./irom.hex";
  
  reg [31:0] data_array[(1024 * 16)-1:0];
  reg [31:0] data_out;
  
  initial
  begin
    $readmemh(IROM_DATA_FILE, data_array);
  end

  always @ (posedge CLK)
    if (CS)
      data_out <= data_array[ADDR[23:0]];
  
  assign DOUT = data_out;
  
endmodule
