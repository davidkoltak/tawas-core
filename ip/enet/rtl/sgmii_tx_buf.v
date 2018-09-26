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

    sgmii_fifo sgmii_fifo
    (
        input rst_in,
        input clk_in,
        input clk_out,

        input [8:0] fifo_in,
        input push,
        output full,

        output [8:0] fifo_out,
        input pop,
        output empty
    );

endmodule
