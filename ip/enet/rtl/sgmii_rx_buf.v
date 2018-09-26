/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * Buffer TBI and convert to GMII cycles
 */

module sgmii_rx_buf
(
    input clk_125mhz,
    input rst,

    input tbi_rx_rdy,
    input tbi_rx_clk,

    input sgmii_autoneg_done,
    input [7:0] rx_byte,
    input rx_is_k,
    
    output [7:0] gmii_rxd,
    output gmii_rx_dv,
    output gmii_rx_err
);

    //
    // Skip data (non-k) bytes after any BC command
    //

    reg skip_next;
    reg pkt_vld;
    reg pkt_err;
    
    wire k_idle = rx_is_k && (rx_byte == 8'hBC);
    wire k_cext = rx_is_k && (rx_byte == 8'hF7);
    wire k_sop = rx_is_k && (rx_byte == 8'hFB);
    wire k_eop = rx_is_k && (rx_byte == 8'hFD);
    wire k_err = rx_is_k && (rx_byte == 8'hFE);
    
    always @ (posedge tbi_rx_clk or negedge tbi_rx_rdy)
        if (!tbi_rx_rdy)
        begin
            skip_next <= 1'b0;
            pkt_vld <= 1'b0;
            pkt_err <= 1'b0;
        end
        else if (!sgmii_autoneg_done)
        begin
            skip_next <= 1'b0;
            pkt_vld <= 1'b0;
            pkt_err <= 1'b0;
        end
        else
        begin
            skip_next <= k_idle;
            pkt_vld <= (pkt_vld || k_sop) && !k_eop;
            pkt_err <= (pkt_err || k_err) && !k_eop;
        end
            
    //
    // RX buffer write
    //
    
    sgmii_fifo sgmii_fifo
    (
        .rst_in(sgmii_autoneg_done),
        .clk_in(tbi_rx_clk),
        .clk_out(clk_125mhz),

        .fifo_in({pkt_err, rx_byte}),
        .push(),
        .full(),

        .fifo_out(),
        .pop(),
        .empty()
    );
        
endmodule
