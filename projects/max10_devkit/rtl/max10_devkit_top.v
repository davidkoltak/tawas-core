/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Intel PSG Max 10 DevKit Reference Design
// 

module max10_devkit_top 
(
    input clk_50,
    input fpga_reset_n,

    output qspi_clk,
    inout [3:0] qspi_io,
    output qspi_csn,

    input uart_rx,
    output uart_tx,

    output [4:0] user_led,
    input [3:0] user_pb
);

    assign user_led = 5'b0;

    wire irom_cs;
    wire [23:0] irom_addr;
    wire [31:0] irom_data;
  
    irom irom
    (
        .clk(clk_50),

        .addr(irom_addr),
        .cs(irom_cs),
        .dout(irom_data)
    );

    wire [31:0] dram_addr;
    wire dram_cs;
    wire dram_wr;
    wire [3:0] dram_mask;
    wire [31:0] dram_din;
    wire [31:0] dram_dout;
    
    dram dram
    (
        .clk(clk_50),

        .addr(dram_addr),
        .cs(dram_cs),
        .wr(dram_wr),
        .mask(dram_mask),
        .din(dram_din),
        .dout(dram_dout)
    );
  
    wire [31:0] test_progress;
    wire [31:0] test_fail;
    wire [31:0] test_pass;

    wire [66:0] rcn_0;
    wire [66:0] rcn_1;
    wire [66:0] rcn_2;
  
    tawas tawas
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),
        .ics(irom_cs),
        .iaddr(irom_addr),
        .idata(irom_data),

        .daddr(dram_addr),
        .dcs(dram_cs),
        .dwr(dram_wr),
        .dmask(dram_mask),
        .dout(dram_din),
        .din(dram_dout),

        .rcn_in(rcn_0),
        .rcn_out(rcn_1)
    );

    rcn_testregs #(.ADDR_BASE(32'hFFFFFFF0)) rcn_testregs
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .test_progress(),
        .test_progress(),
        .test_pass(),

        .rcn_in(rcn_1),
        .rcn_out(rcn_2)
    );

    sram #(.ADDR_BASE(32'h00000000)) sram
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .rcn_in(rcn_2),
        .rcn_out(rcn_0)
    );

endmodule
