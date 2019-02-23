/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// RCN bus RAM
//

module rcn_ram
(
    input clk,
    input rst,

    input [68:0] rcn_in,
    output [68:0] rcn_out
);
    parameter ADDR_BASE = 0;

    wire cs;
    wire wr;
    wire [3:0] mask;
    wire [23:0] addr;
    wire [31:0] wdata;
    wire [31:0] rdata;

    rcn_slave #(.ADDR_MASK(24'hFF0000), .ADDR_BASE(ADDR_BASE)) rcn_slave
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

    reg [7:0] byte_0[(1024 * 16)-1:0];
    reg [7:0] byte_1[(1024 * 16)-1:0];
    reg [7:0] byte_2[(1024 * 16)-1:0];
    reg [7:0] byte_3[(1024 * 16)-1:0];
    reg [31:0] data_out;

    always @ (posedge clk)
        if (cs && wr)
        begin
            if (mask[0])
                byte_0[addr[15:2]] <= wdata[7:0];
            if (mask[1])
                byte_1[addr[15:2]] <= wdata[15:8];
            if (mask[2])
                byte_2[addr[15:2]] <= wdata[23:16];
            if (mask[3])
                byte_3[addr[15:2]] <= wdata[31:24];
        end
        
    always @ (posedge clk)
        if (cs)
            data_out <= {byte_3[addr[15:2]], byte_2[addr[15:2]],
                         byte_1[addr[15:2]], byte_0[addr[15:2]]};

    assign rdata = data_out;

endmodule
