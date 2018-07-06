/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Instruction ROM for Tawas Core
// 

module irom
(
    input clk,

    input [23:0] addr,
    input cs,
    output [31:0] dout
);
    parameter IROM_DATA_FILE = "irom.hex";
  
    reg [31:0] data_array[(1024 * 8)-1:0];
    reg [31:0] data_out;

    initial
    begin
        $readmemh(IROM_DATA_FILE, data_array);
    end

    always @ (posedge clk)
        if (cs)
            data_out <= data_array[addr[13:0]];

    assign dout = data_out;
  
endmodule
