/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas Register File:
//
// This module contains the register file (16 x 32-bit registers) and
// all the read/write muxing logic.
//

module tawas_regfile
(
    input clk,
    input rst,

    input [1:0] slice,

    input pc_store,
    input [23:0] pc_in,
    input [7:0] au_flags,

    output [23:0] pc_rtn,
    output [7:0] au_flags_rtn,

    input rf_imm_vld,
    input [3:0] rf_imm_sel,
    input [31:0] rf_imm,

    input [3:0] au_ra_sel,
    output [31:0] au_ra,

    input [3:0] au_rb_sel,
    output [31:0] au_rb,

    input au_rc_vld,
    input [3:0] au_rc_sel,
    input [31:0] au_rc,

    input [2:0] ls_ptr_sel,
    output [31:0] ls_ptr,

    input [3:0] ls_store_sel,
    output [31:0] ls_store,

    input ls_ptr_upd_vld,
    input [2:0] ls_ptr_upd_sel,
    input [31:0] ls_ptr_upd,

    input ls_load_vld,
    input [3:0] ls_load_sel,
    input [31:0] ls_load,

    input rcn_load_vld,
    input [1:0] rcn_load_slice,
    input [3:0] rcn_load_sel,
    input [31:0] rcn_load
);

    reg [31:0] regfile_0[15:0];
    reg [31:0] regfile_0_nxt[15:0];
    reg [31:0] regfile_1[15:0];
    reg [31:0] regfile_1_nxt[15:0];
    reg [31:0] regfile_2[15:0];
    reg [31:0] regfile_2_nxt[15:0];
    reg [31:0] regfile_3[15:0];
    reg [31:0] regfile_3_nxt[15:0];
  
    integer x;

    always @ *
    begin
        for (x = 0; x < 16; x = x + 1)
        begin
            regfile_0_nxt[x] = regfile_0[x];
            regfile_1_nxt[x] = regfile_1[x];
            regfile_2_nxt[x] = regfile_2[x];
            regfile_3_nxt[x] = regfile_3[x];
        end

        if (rcn_load_vld)
            case (rcn_load_slice[1:0])
            2'd0: regfile_0_nxt[rcn_load_sel] = rcn_load;
            2'd1: regfile_1_nxt[rcn_load_sel] = rcn_load;
            2'd2: regfile_2_nxt[rcn_load_sel] = rcn_load;
            default: regfile_3_nxt[rcn_load_sel] = rcn_load;
            endcase
                
        case (slice[1:0])
        2'd0:
        begin
            if (pc_store)
                regfile_3_nxt[7] = {au_flags, pc_in};

            if (rf_imm_vld)
                regfile_3_nxt[rf_imm_sel] = rf_imm;

            if (au_rc_vld)
                regfile_1_nxt[au_rc_sel] = au_rc;

            if (ls_ptr_upd_vld)
                regfile_2_nxt[ls_ptr_upd_sel + 8] = ls_ptr_upd;

            if (ls_load_vld)
                regfile_0_nxt[ls_load_sel] = ls_load;
        end
        2'd1:
        begin
            if (pc_store)
                regfile_0_nxt[7] = {au_flags, pc_in};

            if (rf_imm_vld)
                regfile_0_nxt[rf_imm_sel] = rf_imm;

            if (au_rc_vld)
                regfile_2_nxt[au_rc_sel] = au_rc;

            if (ls_ptr_upd_vld)
                regfile_3_nxt[ls_ptr_upd_sel + 8] = ls_ptr_upd;

            if (ls_load_vld)
                regfile_1_nxt[ls_load_sel] = ls_load;
        end
        2'd2:
        begin
            if (pc_store)
                regfile_1_nxt[7] = {au_flags, pc_in};

            if (rf_imm_vld)
                regfile_1_nxt[rf_imm_sel] = rf_imm;

            if (au_rc_vld)
                regfile_3_nxt[au_rc_sel] = au_rc;

            if (ls_ptr_upd_vld)
                regfile_0_nxt[ls_ptr_upd_sel + 8] = ls_ptr_upd;

            if (ls_load_vld)
                regfile_2_nxt[ls_load_sel] = ls_load;
        end
        default:
        begin
            if (pc_store)
                regfile_2_nxt[7] = {au_flags, pc_in};

            if (rf_imm_vld)
                regfile_2_nxt[rf_imm_sel] = rf_imm;

            if (au_rc_vld)
                regfile_0_nxt[au_rc_sel] = au_rc;

            if (ls_ptr_upd_vld)
                regfile_1_nxt[ls_ptr_upd_sel + 8] = ls_ptr_upd;

            if (ls_load_vld)
                regfile_3_nxt[ls_load_sel] = ls_load;
        end
        endcase
    end
  
    always @ (posedge clk or posedge rst)
        if (rst)
        for (x = 0; x < 16; x = x + 1)
        begin
            regfile_0[x] <= 32'd0;
            regfile_1[x] <= 32'd0;
            regfile_2[x] <= 32'd0;
            regfile_3[x] <= 32'd0;
        end
        else
        for (x = 0; x < 16; x = x + 1)
        begin
            regfile_0[x] <= regfile_0_nxt[x];
            regfile_1[x] <= regfile_1_nxt[x];
            regfile_2[x] <= regfile_2_nxt[x];
            regfile_3[x] <= regfile_3_nxt[x];
        end

    reg [31:0] pc_out;
    reg [31:0] ra_out;
    reg [31:0] rb_out;
    reg [31:0] ptr_out;
    reg [31:0] st_out;
  
    always @ *
        case (slice[1:0])
        2'd0:
        begin
            pc_out = regfile_3[7];
            ra_out = regfile_3[au_ra_sel];
            rb_out = regfile_3[au_rb_sel];
            ptr_out = regfile_3[ls_ptr_sel + 8];
            st_out = regfile_3[ls_store_sel];
        end
        2'd1:
        begin
            pc_out = regfile_0[7];
            ra_out = regfile_0[au_ra_sel];
            rb_out = regfile_0[au_rb_sel];
            ptr_out = regfile_0[ls_ptr_sel + 8];
            st_out = regfile_0[ls_store_sel];
        end
        2'd2:
        begin
            pc_out = regfile_1[7];
            ra_out = regfile_1[au_ra_sel];
            rb_out = regfile_1[au_rb_sel];
            ptr_out = regfile_1[ls_ptr_sel + 8];
            st_out = regfile_1[ls_store_sel];
        end
        default:
        begin
            pc_out = regfile_2[7];
            ra_out = regfile_2[au_ra_sel];
            rb_out = regfile_2[au_rb_sel];
            ptr_out = regfile_2[ls_ptr_sel + 8];
            st_out = regfile_2[ls_store_sel];
        end
        endcase
      
    assign pc_rtn = pc_out[23:0];
    assign au_flags_rtn = pc_out[31:24];
    assign au_ra = ra_out;  
    assign au_rb = rb_out;

    assign ls_ptr = ptr_out; 
    assign ls_store = st_out; 

    //
    // wires for simulation only... provides visibility with waveform viewers that cannot read arrays
    //

    wire [31:0] s0_r0;
    wire [31:0] s0_r1;
    wire [31:0] s0_r2;
    wire [31:0] s0_r3;
    wire [31:0] s0_r4;
    wire [31:0] s0_r5;
    wire [31:0] s0_r6;
    wire [31:0] s0_r7;
    wire [31:0] s0_r8;
    wire [31:0] s0_r9;
    wire [31:0] s0_r10;
    wire [31:0] s0_r11;
    wire [31:0] s0_r12;
    wire [31:0] s0_r13;
    wire [31:0] s0_r14;
    wire [31:0] s0_r15;

    wire [31:0] s1_r0;
    wire [31:0] s1_r1;
    wire [31:0] s1_r2;
    wire [31:0] s1_r3;
    wire [31:0] s1_r4;
    wire [31:0] s1_r5;
    wire [31:0] s1_r6;
    wire [31:0] s1_r7;
    wire [31:0] s1_r8;
    wire [31:0] s1_r9;
    wire [31:0] s1_r10;
    wire [31:0] s1_r11;
    wire [31:0] s1_r12;
    wire [31:0] s1_r13;
    wire [31:0] s1_r14;
    wire [31:0] s1_r15;

    wire [31:0] s2_r0;
    wire [31:0] s2_r1;
    wire [31:0] s2_r2;
    wire [31:0] s2_r3;
    wire [31:0] s2_r4;
    wire [31:0] s2_r5;
    wire [31:0] s2_r6;
    wire [31:0] s2_r7;
    wire [31:0] s2_r8;
    wire [31:0] s2_r9;
    wire [31:0] s2_r10;
    wire [31:0] s2_r11;
    wire [31:0] s2_r12;
    wire [31:0] s2_r13;
    wire [31:0] s2_r14;
    wire [31:0] s2_r15;

    wire [31:0] s3_r0;
    wire [31:0] s3_r1;
    wire [31:0] s3_r2;
    wire [31:0] s3_r3;
    wire [31:0] s3_r4;
    wire [31:0] s3_r5;
    wire [31:0] s3_r6;
    wire [31:0] s3_r7;
    wire [31:0] s3_r8;
    wire [31:0] s3_r9;
    wire [31:0] s3_r10;
    wire [31:0] s3_r11;
    wire [31:0] s3_r12;
    wire [31:0] s3_r13;
    wire [31:0] s3_r14;
    wire [31:0] s3_r15;

    assign s0_r0 = regfile_0[0];
    assign s0_r1 = regfile_0[1];
    assign s0_r2 = regfile_0[2];
    assign s0_r3 = regfile_0[3];
    assign s0_r4 = regfile_0[4];
    assign s0_r5 = regfile_0[5];
    assign s0_r6 = regfile_0[6];
    assign s0_r7 = regfile_0[7];
    assign s0_r8 = regfile_0[8];
    assign s0_r9 = regfile_0[9];
    assign s0_r10 = regfile_0[10];
    assign s0_r11 = regfile_0[11];
    assign s0_r12 = regfile_0[12];
    assign s0_r13 = regfile_0[13];
    assign s0_r14 = regfile_0[14];
    assign s0_r15 = regfile_0[15];

    assign s1_r0 = regfile_1[0];
    assign s1_r1 = regfile_1[1];
    assign s1_r2 = regfile_1[2];
    assign s1_r3 = regfile_1[3];
    assign s1_r4 = regfile_1[4];
    assign s1_r5 = regfile_1[5];
    assign s1_r6 = regfile_1[6];
    assign s1_r7 = regfile_1[7];
    assign s1_r8 = regfile_1[8];
    assign s1_r9 = regfile_1[9];
    assign s1_r10 = regfile_1[10];
    assign s1_r11 = regfile_1[11];
    assign s1_r12 = regfile_1[12];
    assign s1_r13 = regfile_1[13];
    assign s1_r14 = regfile_1[14];
    assign s1_r15 = regfile_1[15];

    assign s2_r0 = regfile_2[0];
    assign s2_r1 = regfile_2[1];
    assign s2_r2 = regfile_2[2];
    assign s2_r3 = regfile_2[3];
    assign s2_r4 = regfile_2[4];
    assign s2_r5 = regfile_2[5];
    assign s2_r6 = regfile_2[6];
    assign s2_r7 = regfile_2[7];
    assign s2_r8 = regfile_2[8];
    assign s2_r9 = regfile_2[9];
    assign s2_r10 = regfile_2[10];
    assign s2_r11 = regfile_2[11];
    assign s2_r12 = regfile_2[12];
    assign s2_r13 = regfile_2[13];
    assign s2_r14 = regfile_2[14];
    assign s2_r15 = regfile_2[15];

    assign s3_r0 = regfile_3[0];
    assign s3_r1 = regfile_3[1];
    assign s3_r2 = regfile_3[2];
    assign s3_r3 = regfile_3[3];
    assign s3_r4 = regfile_3[4];
    assign s3_r5 = regfile_3[5];
    assign s3_r6 = regfile_3[6];
    assign s3_r7 = regfile_3[7];
    assign s3_r8 = regfile_3[8];
    assign s3_r9 = regfile_3[9];
    assign s3_r10 = regfile_3[10];
    assign s3_r11 = regfile_3[11];
    assign s3_r12 = regfile_3[12];
    assign s3_r13 = regfile_3[13];
    assign s3_r14 = regfile_3[14];
    assign s3_r15 = regfile_3[15];

endmodule
 
