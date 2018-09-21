/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas Module Toplevel: A simple multi-threaded RISC core.
//

`define RTL_VERSION 32'hB0010001

module tawas
(
    input clk,
    input rst,

    output ics,
    output [23:0] iaddr,
    input [31:0] idata,

    output dcs,
    output dwr,
    output [31:0] daddr,
    output [3:0] dmask,
    output [31:0] dout,
    input [31:0] din,

    input [68:0] rcn_in,
    output [68:0] rcn_out
);
    parameter MASTER_ID = 0;

    wire thread_load_en;
    wire [4:0] thread_load;
    wire [4:0] thread_decode;
    wire [4:0] thread_store;

    wire [31:0] thread_mask;

    wire [7:0] au_flags;
    wire [23:0] pc_rtn;

    wire rf_imm_en;
    wire [2:0] rf_imm_reg;
    wire [31:0] rf_imm;

    wire ls_dir_en;
    wire ls_dir_store;
    wire [2:0] ls_dir_reg;
    wire [31:0] ls_dir_addr;

    wire au_op_en;
    wire [14:0] au_op;

    wire ls_op_en;
    wire [14:0] ls_op;

    tawas_fetch tawas_fetch
    (
        .clk(clk),
        .rst(rst),

        .ics(ics),
        .iaddr(iaddr),
        .idata(idata),

        .thread_load_en(thread_load_en),
        .thread_load(thread_load),
        .thread_decode(thread_decode),
        .thread_store(thread_store),

        .thread_mask(thread_mask),

        .au_flags(au_flags),
        .pc_rtn(pc_rtn),

        .rf_imm_en(rf_imm_en),
        .rf_imm_reg(rf_imm_reg),
        .rf_imm(rf_imm),

        .ls_dir_en(ls_dir_en),
        .ls_dir_store(ls_dir_store),
        .ls_dir_reg(ls_dir_reg),
        .ls_dir_addr(ls_dir_addr),

        .au_op_en(au_op_en),
        .au_op(au_op),

        .ls_op_en(ls_op_en),
        .ls_op(ls_op)
    );

    wire [31:0] reg0;
    wire [31:0] reg1;
    wire [31:0] reg2;
    wire [31:0] reg3;
    wire [31:0] reg4;
    wire [31:0] reg5;
    wire [31:0] reg6;
    wire [31:0] reg7;

    assign pc_rtn = reg7[23:0];

    wire [4:0] wb_thread;

    wire wb_au_en;
    wire [2:0] wb_au_reg;
    wire [31:0] wb_au_data;

    wire wb_au_flags_en;
    wire [7:0] wb_au_flags;

    wire wb_ptr_en;
    wire [2:0] wb_ptr_reg;
    wire [31:0] wb_ptr_data;

    wire wb_store_en;
    wire [2:0] wb_store_reg;
    wire [31:0] wb_store_data;

    tawas_regfile tawas_regfile
    (
        .clk(clk),
        .rst(rst),

        .thread_load_en(thread_load_en),
        .thread_load(thread_load),

        .reg0(reg0),
        .reg1(reg1),
        .reg2(reg2),
        .reg3(reg3),
        .reg4(reg4),
        .reg5(reg5),
        .reg6(reg6),
        .reg7(reg7),
        .au_flags(au_flags),

        .wb_thread(wb_thread),

        .wb_au_en(wb_au_en),
        .wb_au_reg(wb_au_reg),
        .wb_au_data(wb_au_data),

        .wb_au_flags_en(wb_au_flags_en),
        .wb_au_flags(wb_au_flags),

        .wb_ptr_en(wb_ptr_en),
        .wb_ptr_reg(wb_ptr_reg),
        .wb_ptr_data(wb_ptr_data),

        .wb_store_en(wb_store_en),
        .wb_store_reg(wb_store_reg),
        .wb_store_data(wb_store_data)
    );

    tawas_au tawas_au
    (
        .clk(clk),
        .rst(rst),

        .reg0(reg0),
        .reg1(reg1),
        .reg2(reg2),
        .reg3(reg3),
        .reg4(reg4),
        .reg5(reg5),
        .reg6(reg6),
        .reg7(reg7),
        .thread_decode(thread_decode),

        .thread_mask(thread_mask),

        .rf_imm_en(rf_imm_en),
        .rf_imm_reg(rf_imm_reg),
        .rf_imm(rf_imm),

        .au_op_en(au_op_en),
        .au_op(au_op),

        .wb_au_en(wb_au_en),
        .wb_au_reg(wb_au_reg),
        .wb_au_data(wb_au_data),

        .wb_au_flags_en(wb_au_flags_en),
        .wb_au_flags(wb_au_flags)
    );

    wire rcn_cs;
    wire rcn_xch;
    wire rcn_wr;
    wire [31:0] rcn_addr;
    wire [2:0] rcn_wbreg;
    wire [3:0] rcn_mask;
    wire [31:0] rcn_wdata;

    tawas_ls tawas_ls
    (
        .clk(clk),
        .rst(rst),

        .reg0(reg0),
        .reg1(reg1),
        .reg2(reg2),
        .reg3(reg3),
        .reg4(reg4),
        .reg5(reg5),
        .reg6(reg6),
        .reg7(reg7),

        .ls_dir_en(ls_dir_en),
        .ls_dir_store(ls_dir_store),
        .ls_dir_reg(ls_dir_reg),
        .ls_dir_addr(ls_dir_addr),

        .ls_op_en(ls_op_en),
        .ls_op(ls_op),

        .dcs(dcs),
        .dwr(dwr),
        .daddr(daddr),
        .dmask(dmask),
        .dout(dout),
        .din(din),

        .rcn_cs(rcn_cs),
        .rcn_xch(rcn_xch),
        .rcn_wr(rcn_wr),
        .rcn_addr(rcn_addr),
        .rcn_wbreg(rcn_wbreg),
        .rcn_mask(rcn_mask),
        .rcn_wdata(rcn_wdata),

        .wb_ptr_en(wb_ptr_en),
        .wb_ptr_reg(wb_ptr_reg),
        .wb_ptr_data(wb_ptr_data),

        .wb_store_en(wb_store_en),
        .wb_store_reg(wb_store_reg),
        .wb_store_data(wb_store_data)
    );

    wire rcn_load_en;
    wire [4:0] rcn_load_thread;
    wire [2:0] rcn_load_reg;
    wire [31:0] rcn_load_data;

    tawas_rcn tawas_rcn
    (
        .clk(clk),
        .rst(rst),

        .thread_store(thread_store),
        .rcn_stall(rcn_stall),

        .rcn_cs(rcn_cs),
        .rcn_xch(rcn_xch),
        .rcn_wr(rcn_wr),
        .rcn_addr(rcn_addr),
        .rcn_wbreg(rcn_wbreg),
        .rcn_mask(rcn_mask),
        .rcn_wdata(rcn_wdata),

        .rcn_load_en(rcn_load_en),
        .rcn_load_thread(rcn_load_thread),
        .rcn_load_reg(rcn_load_reg),
        .rcn_load_data(rcn_load_data),

        .rcn_in(rcn_in),
        .rcn_out(rcn_out)
    );

    //
    // NO RCN LOAD YET
    //

    assign wb_thread = thread_store;

endmodule
