/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// RCN bus sync delay
//

module rcn_delay
(
    input clk,
    input rst,

    input [68:0] rcn_in,
    output [68:0] rcn_out
);
    parameter DELAY_CYCLES = 7;

    reg [68:0] bus_delay[(DELAY_CYCLES-1):0];

    integer x;

    always @ (posedge clk or posedge clk)
        if (rst)
        begin
            for (x = 0; x < DELAY_CYCLES; x = x + 1)
                bus_delay[x] <= 69'd0;
        end
        else
        begin
            bus_delay[(DELAY_CYCLES-1)] <= rcn_in;
            for (x = 1; x < DELAY_CYCLES; x = x + 1)
                bus_delay[x-1] <= bus_delay[x];
        end

    assign rcn_out = bus_delay[0];

endmodule
