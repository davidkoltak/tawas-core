/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// RCN bus UART
//
// Single 32-bit register for byte read/write to 16-entry fifo.
//

module rcn_uart
(
    input clk,
    input clk_50,
    input rst,

    input [66:0] rcn_in,
    output [66:0] rcn_out,

    output tx_req,
    output rx_req,

    output uart_tx,
    input uart_rx
);

    wire cs;
    wire wr;
    wire [3:0] mask;
    wire [23:0] addr;
    wire [31:0] wdata;
    wire [31:0] rdata;

    rcn_slave_fast #(.ADDR_BASE(ADDR_BASE), .ADDR_MASK(24'hFFFFC)) rcn_slave
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

    rcn_uart_framer rcn_uart_framer
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

        .in(wdata[7:0]),
        .push(cs && wr),
        .full(tx_full),

        .dout(tx_data),
        .pop(!tx_busy),
        .empty(tx_empty)
    );

    wire [7:0] rdata_byte;
    wire rx_empty;

    assign rdata = {4{rdata_byte}};
    assign rx_req = !rx_empty;

    rcn_fifo_byte_async rx_fifo
    (
        .rst_in(rst),
        .clk_in(clk_50),
        .clk_out(clk),

        .in(rx_data),
        .push(rx_vld),
        .full(),

        .dout(rdata_byte),
        .pop(cs && !wr),
        .empty(rx_empty)
    );

endmodule
