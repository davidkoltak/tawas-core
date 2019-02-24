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

    reg [7:0] data_array_w0[(1024 * 16)-1:0];
    reg [7:0] data_array_w1[(1024 * 16)-1:0];
    reg [7:0] data_array_w2[(1024 * 16)-1:0];
    reg [7:0] data_array_w3[(1024 * 16)-1:0];
    reg [31:0] data_out;

    initial
    begin
        $readmemh({DRAM_DATA_FILE, ".0"}, data_array_w0);
        $readmemh({DRAM_DATA_FILE, ".1"}, data_array_w1);
        $readmemh({DRAM_DATA_FILE, ".2"}, data_array_w2);
        $readmemh({DRAM_DATA_FILE, ".3"}, data_array_w3);
    end

    always @ (posedge clk)
        if (cs && wr && mask[0])
            data_array_w0[addr[15:2]] <= din[7:0];

    always @ (posedge clk)
        if (cs && wr && mask[1])
            data_array_w1[addr[15:2]] <= din[15:8];

    always @ (posedge clk)
        if (cs && wr && mask[2])
            data_array_w2[addr[15:2]] <= din[23:16];

    always @ (posedge clk)
        if (cs && wr && mask[3])
            data_array_w3[addr[15:2]] <= din[31:24];

    always @ (posedge clk)
        if (cs)
        begin
            data_out[7:0] <= data_array_w0[addr[15:2]];
            data_out[15:8] <= data_array_w1[addr[15:2]];
            data_out[23:16] <= data_array_w2[addr[15:2]];
            data_out[31:24] <= data_array_w3[addr[15:2]];
        end

    assign dout = data_out;

endmodule
