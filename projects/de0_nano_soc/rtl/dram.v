/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Data RAM for Tawas Core
//

module dram
(
    input clk,

    input [31:0] addr,
    input cs,
    input wr,
    input [3:0] mask,
    input [31:0] din,
    output [31:0] dout
);
    parameter DRAM_DATA_FILE = "dram.hex";
  
    reg [31:0] data_array[(1024 * 8)-1:0];
    reg [31:0] data_out;
    wire [31:0] bitmask;

    initial
    begin
        $readmemh(DRAM_DATA_FILE, data_array);
    end

    assign bitmask = {{8{mask[3]}}, {8{mask[2]}}, {8{mask[1]}}, {8{mask[0]}}};

    always @ (posedge clk)
        if (cs && wr)
            data_array[addr[15:2]] <= (data_array[addr[15:2]] & ~bitmask) | (din & bitmask);

    always @ (posedge clk)
        if (cs)
            data_out <= data_array[addr[15:2]];

    assign dout = data_out;
  
endmodule
