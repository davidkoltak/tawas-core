/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * Convert GMII bus to Ten Bit Interface (TBI) used in SGMII
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

endmodule
