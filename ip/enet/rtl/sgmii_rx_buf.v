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
    // RX buffer
    //
    
    wire [8:0] fifo_in = {pkt_err, rx_byte};
    wire fifo_push = !rx_is_k && pkt_vld;
    wire [8:0] fifo_out;
    reg fifo_pop;
    wire fifo_empty;
    
    sgmii_fifo sgmii_fifo
    (
        .rst_in(!sgmii_autoneg_done),
        .clk_in(tbi_rx_clk),
        .clk_out(clk_125mhz),

        .fifo_in(fifo_in),
        .push(fifo_push),
        .full(),

        .fifo_out(fifo_out),
        .pop(fifo_pop),
        .empty(fifo_empty)
    );
    
    //
    // Fifo hystoresis
    //
    
    reg [2:0] cycle_cnt;
    
    always @ (posedge clk_125mhz)
        fifo_pop <= &cycle_cnt[2];
    
    always @ (posedge tbi_rx_clk or negedge sgmii_autoneg_done)
        if (!sgmii_autoneg_done)
            cycle_cnt <= 3'd0;
        else if (fifo_empty)
            cycle_cnt <= 3'd0;
        else if (fifo_push && !fifo_pop)
            cycle_cnt <= cycle_cnt + 3'd1;
    
    //
    // GMII out
    //
    
    assign gmii_rxd = (fifo_pop) ? fifo_out[7:0] : 8'd0;
    assign gmii_rx_dv = fifo_pop;
    assign gmii_rx_err = (fifo_pop) ? fifo_out[8] : 1'b0;
    
endmodule
