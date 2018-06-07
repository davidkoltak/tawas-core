/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Test register module for RCN Bus
//   0x00 : Bus ID
//   0x04 : Test Progress Mark
//   0x08 : Test Fail
//   0x0C : Test Pass
//

module rcn_testregs
(
    input clk,
    input rst,

    input [68:0] rcn_in,
    output [68:0] rcn_out,

    output [31:0] test_progress,
    output [31:0] test_fail,
    output [31:0] test_pass
);
    parameter ADDR_BASE = 0;

    wire cs;
    wire wr;
    wire [23:0] addr;
    wire [31:0] wdata;
    reg [31:0] rdata;

    rcn_slave_fast #(.ADDR_MASK(24'hFFFFF0), .ADDR_BASE(ADDR_BASE)) rcn_slave
    (
        .rst(rst),
        .clk(clk),

        .rcn_in(rcn_in),
        .rcn_out(rcn_out),

        .cs(cs),
        .wr(wr),
        .mask(),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    reg [7:0] id_seq;

    always @ (posedge clk)
        id_seq <= {rcn_in[65:60], rcn_in[33:32]};

    reg [31:0] test_progress_reg;
    reg [31:0] test_fail_reg;
    reg [31:0] test_pass_reg;

    assign test_progress = test_progress_reg;
    assign test_fail = test_fail_reg;
    assign test_pass = test_pass_reg;

    always @ *
        case (addr[3:0])
        4'h0: rdata = {24'd0, id_seq};
        4'h4: rdata = test_progress_reg;
        4'h8: rdata = test_fail_reg;
        default: rdata = test_pass_reg;
        endcase

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            test_progress_reg <= 32'd0;
            test_fail_reg <= 32'd0;
            test_pass_reg <= 32'd0;
        end
        else if (cs && wr)
            case (addr[3:0])
            4'h0: ;
            4'h4: test_progress_reg <= wdata;
            4'h8: test_fail_reg <= wdata;
            default: test_pass_reg <= wdata;
            endcase

endmodule
