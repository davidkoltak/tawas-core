/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * Convert GMII bus to Ten Bit Interface (TBI) used in SGMII.
 * The TBI interface connects to a SERDES transceiver.  This is
 * the top level module. It instantiates the decode/encode, autneg,
 * and FIFO submodules.
 */

module sgmii_tbi
(
    input clk_125mhz,
    input rst,

    output reg autoneg_complete,
    output reg [15:0] config_reg,

    output [7:0] gmii_rxd,
    output gmii_rx_dv,
    output gmii_rx_err,

    input [7:0] gmii_txd,
    input gmii_tx_en,
    input gmii_tx_err,

    input tbi_rx_clk,
    input [9:0] tbi_rxd,

    input tbi_tx_clk,
    output [9:0] tbi_txd,

    output [31:0] dbg_rx,
    output [31:0] dbg_tx
);
    parameter LINK_TIMER = 16'd40000;

    //
    // Decode incoming data stream and autonegotiate
    //

    wire [7:0] rx_byte;
    wire rx_is_k;
    wire rx_disp_err;
    wire sgmii_autoneg_start;
    wire sgmii_autoneg_ack;
    wire sgmii_autoneg_idle;
    wire sgmii_autoneg_done;
    wire [15:0] sgmii_config;

    wire [9:0] tbi_rxd_flip;

    assign tbi_rxd_flip = {tbi_rxd[0], tbi_rxd[1], tbi_rxd[2],
                           tbi_rxd[3], tbi_rxd[4], tbi_rxd[5],
                           tbi_rxd[6], tbi_rxd[7], tbi_rxd[8],
                           tbi_rxd[9]};

    sgmii_8b10b_decode sgmii_8b10b_decode
    (
        .clk(tbi_rx_clk),

        .sgmii_autoneg_start(sgmii_autoneg_start),

        .ten_bit(tbi_rxd_flip),

        .eight_bit(rx_byte),
        .is_k(rx_is_k),
        .disp_err(rx_disp_err)
    );

    sgmii_autoneg #(.LINK_TIMER(LINK_TIMER)) sgmii_autoneg
    (
        .rst(rst),
        .tbi_rx_clk(tbi_rx_clk),

        .rx_byte(rx_byte),
        .rx_is_k(rx_is_k),
        .rx_disp_err(1'b0), //rx_disp_err),

        .sgmii_autoneg_start(sgmii_autoneg_start),
        .sgmii_autoneg_ack(sgmii_autoneg_ack),
        .sgmii_autoneg_idle(sgmii_autoneg_idle),
        .sgmii_autoneg_done(sgmii_autoneg_done),
        .sgmii_config(sgmii_config)
    );

    always @ (posedge clk_125mhz)
    begin
        autoneg_complete <= sgmii_autoneg_done;
        config_reg <= sgmii_config;
    end

    //
    // Convert Rx SGMII to GMII and buffer non-idle cycles
    //

    /*
    wire [7:0] gmii_rxd_flip;

    assign gmii_rxd = {gmii_rxd_flip[0], gmii_rxd_flip[1], gmii_rxd_flip[2],
                       gmii_rxd_flip[3], gmii_rxd_flip[4], gmii_rxd_flip[5],
                       gmii_rxd_flip[6], gmii_rxd_flip[7]};
    */

    sgmii_rx_buf sgmii_rx_buf
    (
        .clk_125mhz(clk_125mhz),
        .rst(rst),

        .tbi_rx_clk(tbi_rx_clk),

        .sgmii_autoneg_done(sgmii_autoneg_done),
        .rx_byte(rx_byte),
        .rx_is_k(rx_is_k),

        .gmii_rxd(gmii_rxd),
        .gmii_rx_dv(gmii_rx_dv),
        .gmii_rx_err(gmii_rx_err)
    );

    //
    // Convert Tx GMII to SGMII and send autoneg cycles based on Rx
    //

    wire [7:0] tx_byte;
    wire tx_is_k;

    wire [9:0] tbi_txd_flip;

    assign tbi_txd = {tbi_txd_flip[0], tbi_txd_flip[1], tbi_txd_flip[2],
                      tbi_txd_flip[3], tbi_txd_flip[4], tbi_txd_flip[5],
                      tbi_txd_flip[6], tbi_txd_flip[7], tbi_txd_flip[8],
                      tbi_txd_flip[9]};
    /*
    wire [7:0] gmii_txd_flip;

    assign gmii_txd_flip = {gmii_txd[0], gmii_txd[1], gmii_txd[2], gmii_txd[3],
                            gmii_txd[4], gmii_txd[5], gmii_txd[6], gmii_txd[7]};
    */

    sgmii_tx_buf #(.LINK_TIMER(LINK_TIMER)) sgmii_tx_buf
    (
        .clk_125mhz(clk_125mhz),
        .rst(rst),

        .tbi_tx_clk(tbi_tx_clk),

        .sgmii_autoneg_start(sgmii_autoneg_start),
        .sgmii_autoneg_ack(sgmii_autoneg_ack),
        .sgmii_autoneg_idle(sgmii_autoneg_idle),
        .sgmii_autoneg_done(sgmii_autoneg_done),

        .gmii_txd(gmii_txd),
        .gmii_tx_en(gmii_tx_en),
        .gmii_tx_err(gmii_tx_err),

        .tx_byte(tx_byte),
        .tx_is_k(tx_is_k)
    );

    sgmii_8b10b_encode sgmii_8b10b_encode
    (
        .clk(tbi_tx_clk),
        .rst(rst),

        .eight_bit(tx_byte),
        .is_k(tx_is_k),

        .ten_bit(tbi_txd_flip)
    );

    assign dbg_rx = {sgmii_autoneg_done, sgmii_autoneg_idle, sgmii_autoneg_ack, sgmii_autoneg_start,
                     2'd0, rx_disp_err, rx_is_k, rx_byte, 16'd0};

    assign dbg_tx = {4'd0, 3'd0, tx_is_k, tx_byte, 16'd0};

endmodule
