/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// RCN bus UART
//
// Registers -
//  0: Status : [rx_empty, tx_full]
//  1: Data   : 8-bit read/write
//

module rcn_uart
(
    input clk,
    input clk_50,
    input rst,

    input [68:0] rcn_in,
    output [68:0] rcn_out,

    output tx_req,
    output rx_req,

    output uart_tx,
    input uart_rx
);
    parameter ADDR_BASE = 0;
    parameter SAMPLE_CLK_DIV = 6'd61; // Value for 115200 @ 50 MHz in

    wire cs;
    wire wr;
    wire [3:0] mask;
    wire [23:0] addr;
    wire [31:0] wdata;
    wire [31:0] rdata;

    rcn_slave_fast #(.ADDR_BASE(ADDR_BASE), .ADDR_MASK(24'hFFFFFC)) rcn_slave
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

    wire tx_busy;
    wire tx_vld;
    wire [7:0] tx_data;

    wire rx_vld;
    wire [7:0] rx_data;

    rcn_uart_framer #(.SAMPLE_CLK_DIV(SAMPLE_CLK_DIV)) rcn_uart_framer
    (
        .clk_50(clk_50),
        .rst(rst),

        .tx_busy(tx_busy),
        .tx_vld(tx_vld),
        .tx_data(tx_data),

        .rx_vld(rx_vld),
        .rx_data(rx_data),
        .rx_frame_error(),

        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

    wire tx_full;
    wire tx_empty;

    assign tx_req = !tx_full;
    assign tx_vld = !tx_empty;

    rcn_fifo_byte_async tx_fifo
    (
        .rst_in(rst),
        .clk_in(clk),
        .clk_out(clk_50),

        .din(wdata[7:0]),
        .push(cs && wr && mask[1]),
        .full(tx_full),

        .dout(tx_data),
        .pop(!tx_busy),
        .empty(tx_empty)
    );

    wire [7:0] rdata_byte;
    wire rx_empty;

    assign rdata = {16'd0, rdata_byte, 6'd0, rx_empty, tx_full};
    assign rx_req = !rx_empty;

    rcn_fifo_byte_async rx_fifo
    (
        .rst_in(rst),
        .clk_in(clk_50),
        .clk_out(clk),

        .din(rx_data),
        .push(rx_vld),
        .full(),

        .dout(rdata_byte),
        .pop(cs && !wr && mask[1]),
        .empty(rx_empty)
    );

endmodule
