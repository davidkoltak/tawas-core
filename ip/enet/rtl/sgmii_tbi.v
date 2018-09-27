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
    
    input tbi_rx_rdy,
    input tbi_rx_clk,
    input [9:0] tbi_rxd,
    
    input tbi_tx_rdy,
    input tbi_tx_clk,
    output [9:0] tbi_txd
);

    //
    // Decode incoming data stream and autonegotiate
    //

    wire [7:0] rx_byte;
    wire rx_is_k;
    wire rx_disp_err;
    wire sgmii_autoneg_start;
    wire sgmii_autoneg_done;
    wire [15:0] sgmii_config;
    
    sgmii_8b10b_decode sgmii_8b10b_decode
    (
        .clk(tbi_rx_clk),
        
        .sgmii_autoneg_start(sgmii_autoneg_start),
    
        .ten_bit(tbi_rxd),
        
        .eight_bit(rx_byte),
        .is_k(rx_is_k),
        .disp_err(rx_disp_err)
    );

    sgmii_autoneg sgmii_autoneg
    (
        .tbi_rx_rdy(tbi_rx_rdy),
        .tbi_rx_clk(tbi_rx_clk),
        
        .rx_byte(rx_byte),
        .rx_is_k(rx_is_k),
        
        .sgmii_autoneg_start(sgmii_autoneg_start),
        .sgmii_autoneg_done(sgmii_autoneg_done),
        .sgmii_config(sgmii_config)
    );

    always @ (clk_125mhz)
    begin
        autoneg_complete <= sgmii_autoneg_done;
        config_reg <= sgmii_config;
    end

    //
    // Convert Rx SGMII to GMII and buffer non-idle cycles
    //
    
    sgmii_rx_buf sgmii_rx_buf
    (
        .clk_125mhz(clk_125mhz),
        .rst(rst),

        .tbi_rx_rdy(tbi_rx_rdy),
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
    
    sgmii_tx_buf sgmii_tx_buf
    (
        .clk_125mhz(clk_125mhz),
        .rst(rst),

        .tbi_tx_rdy(tbi_tx_rdy),
        .tbi_tx_clk(tbi_tx_clk),

        .sgmii_autoneg_start(sgmii_autoneg_start),
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
        .rst(!tbi_tx_rdy),
        
        .eight_bit(tx_byte),
        .is_k(tx_is_k),
        
        .ten_bit(tbi_tx)
    );
    
endmodule
