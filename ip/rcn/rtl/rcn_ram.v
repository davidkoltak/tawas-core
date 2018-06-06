/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// RCN bus RAM
//

module rcn_ram
(
    input clk,
    input rst,
    
    input [66:0] rcn_in,
    output [66:0] rcn_out
);
    parameter ADDR_BASE = 0;

    wire cs;
    wire wr;
    wire [3:0] mask;
    wire [21:0] addr;
    wire [31:0] wdata;
    wire [31:0] rdata;
        
    rcn_slave #(.ADDR_MASK(32'hFFFF0000), .ADDR_BASE(ADDR_BASE)) rcn_slave
    (
        .rst(rst),
        .clk(clk),
        
        .rcn_in(rcn_in),
        .rcn_out(rcn_out),
        
        .cs(cs),
        .wr(wr),
        .mask(mask),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    reg [31:0] data_array[(1024 * 16)-1:0];
    reg [31:0] data_out;
    wire [31:0] bitmask;
    
    assign bitmask = {{8{mask[3]}}, {8{mask[2]}}, {8{mask[1]}}, {8{mask[0]}}};

    always @ (posedge clk)
        if (cs && wr)
            data_array[addr[15:2]] <= (data_array[addr[15:2]] & ~bitmask) | (wdata & bitmask);

    always @ (posedge clk)
        if (cs)
            data_out <= data_array[addr[15:2]];

    assign rdata = data_out;

endmodule
