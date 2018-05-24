/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// RCN bus UART
//

module rcn_uart
(
    input clk,
    input rst,
    
    input [66:0] rcn_in,
    output [66:0] rcn_out,
    
    input uart_rx,
    output uart_tx
);

endmodule
