/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * Buffer GMII cycles and convert to TBI - send SGMII autoneg cycles
 */

module sgmii_tx_buf
(
    input clk_125mhz,
    input rst,

    input tbi_tx_rdy,
    input tbi_tx_clk,

    input sgmii_autoneg_start,
    input sgmii_autoneg_done,
    
    input [7:0] gmii_txd,
    input gmii_tx_en,
    input gmii_tx_err,
    
    output [7:0] tx_byte,
    output tx_is_k
);

    //
    // TX buffer write
    //
    
    wire [8:0] fifo_in = {gmii_tx_err, gmii_txd};
    wire fifo_push = gmii_tx_en && sgmii_autoneg_done;
    wire [8:0] fifo_out;
    reg fifo_pop;
    wire fifo_empty;
    
    sgmii_fifo sgmii_fifo
    (
        .rst_in(rst),
        .clk_in(clk_125mhz),
        .clk_out(tbi_tx_clk),

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
    
    always @ (posedge tbi_tx_clk)
        fifo_pop <= &cycle_cnt[2];
    
    always @ (posedge clk_125mhz or posedge rst)
        if (rst)
            cycle_cnt <= 3'd0;
        else if (fifo_empty)
            cycle_cnt <= 3'd0;
        else if (fifo_push && !fifo_pop)
            cycle_cnt <= cycle_cnt + 3'd1;

    //
    // TBI out
    //
    
    assign tx_byte
    assign tx_is_k
    
endmodule
