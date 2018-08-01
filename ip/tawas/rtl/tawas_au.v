/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas Arithmetic Unit:
//
// Perform arithmetic on registers.
//

module tawas_au
(
    input clk,
    input rst,
    
    input [255:0] regdata,

    input rf_imm_en,
    input [2:0] rf_imm_reg,
    input [31:0] rf_imm,

    input au_op_en,
    input [14:0] au_op,
    
    output wb_au_en,
    output [2:0] wb_au_reg,
    output [31:0] wb_au_data,

    output wb_au_flags_en,
    output [7:0] wb_au_flags
);
    parameter RTL_VERSION = 32'hFFFFFFFF;

endmodule
