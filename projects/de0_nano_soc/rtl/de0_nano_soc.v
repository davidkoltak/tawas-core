/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Terasic DE0 Nano SoC (Cyclone V SoC) Development Board
//

module de0_nano_soc
(
    input FPGA_CLK1_50,
    input FPGA_CLK2_50,
    input FPGA_CLK3_50,
    
    input [1:0] BUTTON,
    input [3:0] SW,
    output [7:0] LED,
    
    output UART_TX,
    input UART_RX,
    
    output SPDR_TX,
    input SPDR_RX
);

    wire clk_50 = FPGA_CLK1_50;
    wire clk_slow = FPGA_CLK2_50;
    wire fpga_reset_n = BUTTON[0]; // NOTE: Debounced on board
    
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

    wire [68:0] rcn_00;
    wire [68:0] rcn_01;
    wire [68:0] rcn_02;
    wire [68:0] rcn_03;
    wire [68:0] rcn_04;

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

    wire [31:0] test_progress;
    wire [31:0] test_fail;
    wire [31:0] test_pass;
    
    rcn_testregs #(.ADDR_BASE(24'hFFFFF0)) testregs
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .test_progress(),
        .test_progress(),
        .test_pass(),

        .rcn_in(rcn_01),
        .rcn_out(rcn_02)
    );

    rcn_ram #(.ADDR_BASE(24'hFE0000)) sram_0
    (
        .clk(clk_50),
        .rst(!fpga_reset_n),

        .rcn_in(rcn_02),
        .rcn_out(rcn_03)
    );

    wire uart_tx_req;
    wire uart_rx_req;

    rcn_uart #(.ADDR_BASE(24'hFFFFB8)) uart
    (
        .clk(clk_50),
        .clk_50(clk_50),
        .rst(!fpga_reset_n),

        .rcn_in(rcn_03),
        .rcn_out(rcn_04),

        .tx_req(uart_tx_req),
        .rx_req(uart_rx_req),

        .uart_tx(UART_TX),
        .uart_rx(UART_RX)
    );

    wire [68:0] rcn_20;
    wire [68:0] rcn_21;
    wire [68:0] rcn_22;

    rcn_bridge_async #(.ID_MASK(6'h3C), .ID_BASE(6'h08),
                       .ADDR_MASK(24'hF00000), .ADDR_BASE(24'h100000))  bridge
    (
        .main_clk(clk_50),
        .main_rst(!fpga_reset_n),
        .sub_clk(clk_slow),

        .main_rcn_in(rcn_04),
        .main_rcn_out(rcn_00),

        .sub_rcn_in(rcn_20),
        .sub_rcn_out(rcn_21)
    );

    wire [31:0] spdr_gpo;
    assign LED[7:0] = spdr_gpo[7:0];
    
    rcn_spdr #(.MASTER_ID(9)) spdr
    (
        .clk(clk_slow),
        .clk_50(clk_50),
        .rst(!fpga_reset_n),

        .rcn_in(rcn_21),
        .rcn_out(rcn_22),

        .gpi({28'd0, SW[3:0]}),
        .gpi_strobe(),
        .gpo(spdr_gpo),
        .gpo_strobe(),

        .uart_tx(SPDR_TX),
        .uart_rx(SPDR_RX)
    );

    rcn_dma #(.ADDR_BASE(24'h1FFFC0), .MASTER_ID(8)) dma
    (
        .clk(clk_slow),
        .rst(!fpga_reset_n),

        .rcn_in(rcn_22),
        .rcn_out(rcn_20),

        .req({uart_rx_req, uart_tx_req, 14'd1}),
        .done()
    );

endmodule
