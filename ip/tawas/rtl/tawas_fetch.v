/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas Instruction Fetch
//
//  Pick thread for each cycle and decode br and full word instructions.
//

module tawas_fetch
(
    input clk,
    input rst,

    output ics,
    output [23:0] iaddr,
    input [31:0] idata,

    output thread_load_en,
    output [4:0] thread_load,
    output [4:0] thread_decode,
    output [4:0] thread_store,

    input [31:0] thread_mask,
    input [31:0] rcn_stall,
    input rcn_load_en,
    
    input [7:0] au_flags,
    input [23:0] pc_rtn,

    output rf_imm_en,
    output [2:0] rf_imm_reg,
    output [31:0] rf_imm,

    output ls_dir_en,
    output ls_dir_store,
    output [2:0] ls_dir_reg,
    output [31:0] ls_dir_addr,
    
    output au_op_en,
    output [14:0] au_op,

    output ls_op_en,
    output [14:0] ls_op
);

    //
    // Thread PC's : 24-bit PC + 1-bit half-word-select
    //

    wire pc_update_en;
    wire [4:0] pc_update_sel;
    wire [24:0] pc_update_addr;

    reg [24:0] pc[31:0];

    integer x1;

    always @ (posedge clk or posedge rst)
        if (rst)
            for (x1 = 0; x1 < 32; x1 = x1 + 1)
                pc[x1] <= x1;
        else if (pc_update_en)
            pc[pc_update_sel] <= pc_update_addr;

    //
    // Choose thread to execute
    //

    reg [31:0] thread_busy;
    reg [31:0] thread_ready;
    reg [31:0] thread_done_mask;
    reg [31:0] s1_sel_mask;
    reg [4:0] s1_sel;
    reg s1_en;

    wire thread_retire_en;
    wire [4:0] thread_retire;
    
    integer x2;

    always @ *
    begin
        s1_sel_mask = 32'd0;
        s1_sel = 5'd0;
        s1_en = 1'b0;
        thread_done_mask = 32'd0;

        thread_ready = (~thread_busy) & thread_mask & (!rcn_stall);
        
        for (x2 = 0; x2 < 32; x2 = x2 + 1)
            if (!s1_en && thread_ready[x2])
            begin
                s1_sel_mask = (32'd1 << x2);
                s1_sel = x2;
                s1_en = 1'b1;
            end

        if (thread_retire_en) 
            thread_done_mask = (32'd1 << thread_retire);
            
        if (thread_abort_en) 
            thread_done_mask = (32'd1 << thread_abort);
    end

    always @ (posedge clk or posedge rst)
        if (rst)
            thread_busy <= 32'd0;
        else
            thread_busy <= (thread_busy | s1_sel_mask) & ~thread_done_mask;

    //
    // En/Sel pipeline
    //

    reg s2_en;
    reg [4:0] s2_sel;
    reg [24:0] s2_pc;

    reg s3_en;
    reg [4:0] s3_sel;
    reg [24:0] s3_pc;

    reg s4_en;
    reg [4:0] s4_sel;
    reg [24:0] s4_pc;

    wire s6_halt;
    reg s5_en;
    reg [4:0] s5_sel;
    
    reg s6_en;
    reg [4:0] s6_sel;

    reg [4:0] s7_sel;
    
    assign ics = s2_en;
    assign iaddr = s2_pc[23:0];
    
    reg [31:0] instr;

    always @ (posedge clk)
    begin
        s2_pc <= pc[s1_sel];
        s3_pc <= s2_pc;
        s4_pc <= s3_pc;
        
        s2_sel <= s1_sel;
        s3_sel <= s2_sel;
        s4_sel <= s3_sel;
        s5_sel <= s4_sel;
        s6_sel <= s5_sel;
        s7_sel <= s6_sel;
    end

    always @ (posedge clk)
        if (s3_en)
            instr <= idata;

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            s2_en <= 1'b0;
            s3_en <= 1'b0;
            s4_en <= 1'b0;
            s5_en <= 1'b0;
            s6_en <= 1'b0;
        end
        else
        begin
            s2_en <= s1_en;
            s3_en <= s2_en;
            s4_en <= s3_en && !thread_abort_en;
            s5_en <= s4_en && !s5_halt;
            s6_en <= s5_en;
        end

    //
    // Decode Instructions
    //

    wire [14:0] op_high = instr[29:15];
    wire [14:0] op_low = instr[14:0];
    wire [12:0] op_br = instr[27:15];

    wire op_high_vld = !instr[31] || !instr[30];
    wire op_high_au = (instr[31:30] == 2'b00);

    wire op_low_vld = !instr[31] || !instr[30] || !instr[29];
    wire op_low_au = !instr[30] || (instr[31:28] == 4'b1100);

    wire op_serial = !instr[31];
    
    wire op_br_vld = (instr[31:29] == 3'b110);

    wire op_is_br = op_br_vld && !op_br[12];
    wire [23:0] op_br_iaddr = s4_pc[23:0] + {{12{op_br[11]}}, op_br[11:0]};

    wire op_is_halt = op_br_vld && (op_br[12:0] == 13'd0);

    wire op_is_br_cond = op_br_vld && op_br[12];
    wire op_br_cond_true = (op_br[11]) ? !au_flags[op_br[10:8]] : au_flags[op_br[10:8]];
    wire [23:0] op_br_cond_iaddr = s4_pc[23:0] + {{16{op_br[7]}}, op_br[7:0]};

    wire op_is_rtn = op_br_vld && op_br[12] && (op_br[7:0] == 8'd1);

    wire op_is_imm = (instr[31:28] == 4'b1110);
    wire [2:0] op_imm_reg = instr[27:25];
    wire [31:0] op_imm = {{8{instr[24]}}, instr[23:0]};

    wire op_is_dir_ld = (instr[31:26] == 6'b111100);
    wire op_is_dir_st = (instr[31:26] == 6'b111101);
    wire [2:0] op_dir_reg = instr[25:23];
    wire [31:0] op_daddr = {{8{instr[22]}}, instr[21:0], 2'b00};

    wire op_is_jmp = (instr[31:24] == 8'b11111110);
    wire op_is_call = (instr[31:24] == 8'b11111111);
    wire [23:0] op_iaddr = instr[23:0];

    //
    // PC Update
    //

    wire [24:0] pc_next = (op_serial && !s4_pc[24]) ? {1'b1, s4_pc[23:0]}
                                                    : {1'b0, s4_pc[23:0] + 24'b1};

    assign pc_update_en = s4_en;
    assign pc_update_sel = s4_sel;
    assign pc_update_addr = (op_is_call || op_is_jmp) ? {1'b0, op_iaddr} :
                            (op_is_rtn) ? {1'b0, pc_rtn} :
                            (op_is_br) ? {1'b0, op_br_iaddr} :
                            (op_is_br_cond && op_br_cond_true) ? {1'b0, op_br_cond_iaddr}
                                                               : pc_next;
    
    //
    // Load thread register context
    //
    
    assign thread_load_en = s3_en;
    assign thread_load = s3_sel;
    
    assign thread_decode = s4_sel;
    assign thread_store = s7_sel;

    //
    // Retire/abort/halt thread
    //
    
    assign thread_abort_en = rcn_load_en;
    assign thread_abort = s3_sel;

    assign s5_halt = op_is_halt;

    assign thread_retire_en = s6_en;
    assign thread_retire = s6_sel;
                                                 
    //
    // Imm/Dir data loads
    //
    
    assign rf_imm_en = s4_en && (op_is_imm || op_is_call);
    assign rf_imm_reg = (op_is_imm) ? op_imm_reg : 3'd7;
    assign rf_imm = (op_is_imm) ? op_imm : {8'd0, s4_pc + 24'b1};
    
    assign ls_dir_en = s4_en && (op_is_dir_ld || op_is_dir_st);
    assign ls_dir_store = op_is_dir_st;
    assign ls_dir_reg = op_dir_reg;
    assign ls_dir_addr = op_daddr;
    
    //
    // LS/AU Ops
    //
    
    wire do_low = (op_serial) ? !s4_pc[24] : op_low_vld;
    wire do_high = (op_serial) ? s4_pc[24] : op_high_vld;
    
    assign au_op_en = s4_en && ((do_high && op_high_au) || (do_low && op_low_au));
    assign au_op = (do_high && op_high_au) ? op_high : op_low;

    assign ls_op_en = s4_en && 
                    ((do_high && !op_high_au) || (do_low && !op_low_au) || op_is_call);
    assign ls_op = (op_is_call) ? 15'h77F7 : 
                   (do_high && !op_high_au) ? op_high : op_low;
       
endmodule
