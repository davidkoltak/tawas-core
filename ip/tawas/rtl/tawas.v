/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas Module Toplevel: A simple multi-threaded RISC core.
//

`define RTL_VERSION 32'hA0010001

module tawas
(
    input clk,
    input rst,

    output ics,
    output [23:0] iaddr,
    input [31:0] idata,

    output [31:0] daddr,
    output dcs,
    output dwr,
    output [3:0] dmask,
    output [31:0] dout,
    input [31:0] din,

    input [66:0] rcn_in,
    output [66:0] rcn_out
);
    parameter MASTER_ID = 0;

    wire pc_store;
    wire [23:0] pc_out;
    wire pc_restore;
    wire [23:0] pc_rtn;

    wire rf_imm_vld;
    wire [2:0] rf_imm_sel;
    wire [31:0] rf_imm;

    wire [1:0] slice;
    wire [7:0] au_flags;

    wire au_op_vld;
    wire [14:0] au_op;

    wire ls_op_vld;
    wire [14:0] ls_op;

    wire ls_dir_vld;
    wire ls_dir_store;
    wire [2:0] ls_dir_sel;
    wire [31:0] ls_dir_addr;

    wire [3:0] rcn_stall;

    tawas_fetch tawas_fetch
    (
        .clk(clk),
        .rst(rst),

        .ics(ics),
        .iaddr(iaddr),
        .idata(idata),

        .slice(slice),
        .au_flags(au_flags),
        .rcn_stall(rcn_stall),

        .pc_store(pc_store),
        .pc_out(pc_out),
        .pc_restore(pc_restore),
        .pc_rtn(pc_rtn),

        .rf_imm_vld(rf_imm_vld),
        .rf_imm_sel(rf_imm_sel),
        .rf_imm(rf_imm),

        .au_op_vld(au_op_vld),
        .au_op(au_op),

        .ls_op_vld(ls_op_vld),
        .ls_op(ls_op),

        .ls_dir_vld(ls_dir_vld),
        .ls_dir_store(ls_dir_store),
        .ls_dir_sel(ls_dir_sel),
        .ls_dir_addr(ls_dir_addr)
    );
  
    wire [7:0] au_flags_rtn;

    wire [2:0] au_ra_sel;
    wire [31:0] au_ra;

    wire [2:0] au_rb_sel;
    wire [31:0] au_rb;

    wire au_rc_vld;
    wire [2:0] au_rc_sel;
    wire [31:0] au_rc;
  
    tawas_au #(.RTL_VERSION(`RTL_VERSION)) tawas_au
    (
        .clk(clk),
        .rst(rst),

        .slice(slice),
        .au_flags(au_flags),

        .pc_restore(pc_restore),
        .au_flags_rtn(au_flags_rtn),

        .au_op_vld(au_op_vld),
        .au_op(au_op),

        .au_ra_sel(au_ra_sel),
        .au_ra(au_ra),

        .au_rb_sel(au_rb_sel),
        .au_rb(au_rb),

        .au_rc_vld(au_rc_vld),
        .au_rc_sel(au_rc_sel),
        .au_rc(au_rc)
    );
  
    wire [31:0] daddr_out;
    wire rcn_cs;
    wire rcn_post;
    wire [2:0] writeback_reg;
    wire dwr_out;
    wire [3:0] dmask_out;
    wire [31:0] dout_out;

    assign daddr = daddr_out;
    assign dwr = dwr_out;
    assign dmask = dmask_out;
    assign dout = dout_out;

    wire [2:0] ls_ptr_sel;
    wire [31:0] ls_ptr;

    wire [2:0] ls_store_sel;
    wire [31:0] ls_store;

    wire ls_ptr_upd_vld;
    wire [2:0] ls_ptr_upd_sel;
    wire [31:0] ls_ptr_upd;

    wire ls_load_vld;
    wire [2:0] ls_load_sel;
    wire [31:0] ls_load;
  
    tawas_ls tawas_ls
    (
        .clk(clk),
        .rst(rst),

        .daddr(daddr_out),
        .dcs(dcs),
        .rcn_cs(rcn_cs),
        .rcn_post(rcn_post),
        .writeback_reg(writeback_reg),
        .dwr(dwr_out),
        .dmask(dmask_out),
        .dout(dout_out),
        .din(din),

        .ls_op_vld(ls_op_vld),
        .ls_op(ls_op),

        .ls_dir_vld(ls_dir_vld),
        .ls_dir_store(ls_dir_store),
        .ls_dir_sel(ls_dir_sel),
        .ls_dir_addr(ls_dir_addr),

        .ls_ptr_sel(ls_ptr_sel),
        .ls_ptr(ls_ptr),

        .ls_store_sel(ls_store_sel),
        .ls_store(ls_store),

        .ls_ptr_upd_vld(ls_ptr_upd_vld),
        .ls_ptr_upd_sel(ls_ptr_upd_sel),
        .ls_ptr_upd(ls_ptr_upd),

        .ls_load_vld(ls_load_vld),
        .ls_load_sel(ls_load_sel),
        .ls_load(ls_load)
    );
  
    wire rcn_load_vld;
    wire [1:0] rcn_load_slice;
    wire [2:0] rcn_load_sel;
    wire [31:0] rcn_load;

    tawas_rcn tawas_rcn
    (
        .clk(clk),
        .rst(rst),

        .slice(slice),
        .rcn_stall(rcn_stall),

        .daddr(daddr_out),
        .rcn_cs(rcn_cs),
        .rcn_post(rcn_post),
        .writeback_reg(writeback_reg),
        .dwr(dwr_out),
        .dmask(dmask_out),
        .dout(dout_out),

        .rcn_load_vld(rcn_load_vld),
        .rcn_load_slice(rcn_load_slice),
        .rcn_load_sel(rcn_load_sel),
        .rcn_load(rcn_load),

        .rcn_in(rcn_in),
        .rcn_out(rcn_out)
    );
    
    tawas_regfile tawas_regfile
    (
        .clk(clk),
        .rst(rst),

        .slice(slice),

        .pc_store(pc_store),
        .pc_in(pc_out),
        .au_flags(au_flags),

        .pc_rtn(pc_rtn),
        .au_flags_rtn(au_flags_rtn),

        .rf_imm_vld(rf_imm_vld),
        .rf_imm_sel(rf_imm_sel),
        .rf_imm(rf_imm),

        .au_ra_sel(au_ra_sel),
        .au_ra(au_ra),

        .au_rb_sel(au_rb_sel),
        .au_rb(au_rb),

        .au_rc_vld(au_rc_vld),
        .au_rc_sel(au_rc_sel),
        .au_rc(au_rc),

        .ls_ptr_sel(ls_ptr_sel),
        .ls_ptr(ls_ptr),

        .ls_store_sel(ls_store_sel),
        .ls_store(ls_store),

        .ls_ptr_upd_vld(ls_ptr_upd_vld),
        .ls_ptr_upd_sel(ls_ptr_upd_sel),
        .ls_ptr_upd(ls_ptr_upd),

        .ls_load_vld(ls_load_vld),
        .ls_load_sel(ls_load_sel),
        .ls_load(ls_load),

        .rcn_load_vld(rcn_load_vld),
        .rcn_load_slice(rcn_load_slice),
        .rcn_load_sel(rcn_load_sel),
        .rcn_load(rcn_load)
    );

endmodule
