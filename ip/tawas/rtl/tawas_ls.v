/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas Load/Store:
//
// Perform load/store operations between the data bus and register file.
//

module tawas_ls
(
    input clk,
    input rst,

    input [255:0] regdata,
    
    input ls_dir_en,
    input ls_dir_store,
    input [2:0] ls_dir_reg,
    input [31:0] ls_dir_addr,
    
    input ls_op_en,
    input [14:0] ls_op,

    output reg dcs,
    output reg dwr,
    output reg [31:0] daddr,
    output reg [3:0] dmask,
    output reg [31:0] dout,
    input [31:0] din,

    output rcn_cs,
    output rcn_xch,
    output rcn_wr,
    output [31:0] rcn_addr,
    output [2:0] rcn_wbreg,
    output [3:0] rcn_mask,
    output [31:0] rcn_wdata,

    output wb_ptr_en,
    output [2:0] wb_ptr_reg,
    output [31:0] wb_ptr_data,

    output wb_store_en,
    output [2:0] wb_store_reg,
    output [31:0] wb_store_data
);


endmodule

