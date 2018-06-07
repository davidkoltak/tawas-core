/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Intel PSG Max 10 DevKit Reference Design
//

module ip_test_top
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

    wire [66:0] rcn_00;
    wire [66:0] rcn_01;
    wire [66:0] rcn_02;
    wire [66:0] rcn_03;
    wire [66:0] rcn_04;

    tawas #(.MASTER_ID(0)) tawas
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),
        .ics(irom_cs),
        .iaddr(irom_addr),
        .idata(irom_data),

        .dcs(dram_cs),
        .dwr(dram_wr),
        .daddr(dram_addr),
        .dmask(dram_mask),
        .dout(dram_din),
        .din(dram_dout),

        .rcn_in(rcn_00),
        .rcn_out(rcn_01)
    );

    rcn_testregs #(.ADDR_BASE(22'h3FFFF0)) testregs
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .test_progress(),
        .test_progress(),
        .test_pass(),

        .rcn_in(rcn_01),
        .rcn_out(rcn_02)
    );

    rcn_ram #(.ADDR_BASE(22'h3E0000)) sram_0
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .rcn_in(rcn_02),
        .rcn_out(rcn_03)
    );

    wire [66:0] rcn_10;
    wire [66:0] rcn_11;
    wire [66:0] rcn_12;

    rcn_bridge #(.ID_MASK(6'h3C), .ID_BASE(6'h04),
                 .ADDR_MASK(22'h300000), .ADDR_BASE(22'h000000)) bridge_1
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .main_rcn_in(rcn_03),
        .main_rcn_out(rcn_04),

        .sub_rcn_in(rcn_10),
        .sub_rcn_out(rcn_11)
    );

    rcn_ram #(.ADDR_BASE(22'h0E0000)) sram_1
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .rcn_in(rcn_11),
        .rcn_out(rcn_12)
    );

    rcn_dma #(.ADDR_BASE(22'h0FFFC0), .MASTER_ID(4)) dma_1
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .rcn_in(rcn_12),
        .rcn_out(rcn_10),

        .req(16'h0001),
        .done()
    );

    wire [66:0] rcn_20;
    wire [66:0] rcn_21;
    wire [66:0] rcn_22;

    rcn_bridge #(.ID_MASK(6'h3C), .ID_BASE(6'h08),
                 .ADDR_MASK(22'h300000), .ADDR_BASE(22'h100000))  rcn_bridge_2
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .main_rcn_in(rcn_04),
        .main_rcn_out(rcn_00),

        .sub_rcn_in(rcn_20),
        .sub_rcn_out(rcn_21)
    );

    rcn_ram #(.ADDR_BASE(22'h1E0000)) sram_2
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .rcn_in(rcn_21),
        .rcn_out(rcn_22)
    );

    rcn_dma #(.ADDR_BASE(22'h1FFFC0), .MASTER_ID(8)) dma_2
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .rcn_in(rcn_22),
        .rcn_out(rcn_20),

        .req(16'h0001),
        .done()
    );

endmodule
