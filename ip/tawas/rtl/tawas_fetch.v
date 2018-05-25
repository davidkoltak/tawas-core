/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas Instruction Fetch:
//
// Fetch instructions from the instruction ROM and execute
// BR, CALL, and IMM instructions.  Generate AU and LS opcode
// control output signals for four "slices" (threads).
//
// Slice 0 starts at instruction offset 0x000000
// Slice 1 starts at instruction offset 0x000001
// Slice 2 starts at instruction offset 0x000002
// Slice 3 starts at instruction offset 0x000003
//

module tawas_fetch
(
    input clk,
    input rst,

    output ics,
    output [23:0] iaddr,
    input [31:0] idata,

    output [1:0] slice,
    input [7:0] au_flags,
    input [3:0] rcn_stall,

    output pc_store,
    output [23:0] pc_out,
    output pc_restore,
    input [23:0] pc_rtn,

    output rf_imm_vld,
    output [2:0] rf_imm_sel,
    output [31:0] rf_imm,

    output au_op_vld,
    output [14:0] au_op,

    output ls_op_vld,
    output [14:0] ls_op,

    output ls_dir_vld,
    output ls_dir_store,
    output [2:0] ls_dir_sel,
    output [31:0] ls_dir_addr
);

    //
    // PC Generation and Redirection for two threads - BR/CALL Decode
    //

    reg au_cond_flag;
    reg au_cond_true;

    reg [23:0] pc_next;
    reg [23:0] pc_inc;
    reg pc_stall;
    reg pc_store_en;
    reg r7_push_en;
    reg pc_restore_en;

    reg instr_vld;
    reg [1:0] pc_sel;
    reg fetch_stall;
    reg fetch_stall_d1;

    reg [23:0] pc;
    reg [23:0] pc_0;
    reg [23:0] pc_1;
    reg [23:0] pc_2;
    reg [23:0] pc_3;
    reg pc_0_nop_loop;
    reg pc_1_nop_loop;
    reg pc_2_nop_loop;
    reg pc_3_nop_loop;
    reg series_cmd_0;
    reg series_cmd_1;
    reg series_cmd_2;
    reg series_cmd_3;
  
    assign slice = pc_sel[1:0];

    assign pc_store = !fetch_stall_d1 && pc_store_en;
    assign pc_out = pc_inc;
    assign pc_restore = !fetch_stall_d1 && pc_restore_en;

    assign iaddr = pc;
    assign ics = !fetch_stall;

    assign cmd_is_nop_loop = instr_vld && (idata[31:0] == 32'hc0000000);

    always @ *
    begin
        case (idata[25:23])
        4'h0: au_cond_flag = au_flags[0];
        4'h1: au_cond_flag = au_flags[1];
        4'h2: au_cond_flag = au_flags[2];
        4'h3: au_cond_flag = au_flags[3];
        4'h4: au_cond_flag = au_flags[4];
        4'h5: au_cond_flag = au_flags[5];
        4'h6: au_cond_flag = au_flags[6];
        default: au_cond_flag = au_flags[7];
        endcase
        au_cond_true = au_cond_flag ^ idata[26];
    end
  
    always @ *
    begin
        case (pc_sel[1:0])
        2'd0: pc_next = pc_3;
        2'd1: pc_next = pc_0;
        2'd2: pc_next = pc_1;
        default: pc_next = pc_2;
        endcase

        case (pc_sel[1:0])
        2'd0: pc_stall = rcn_stall[1] || pc_1_nop_loop;
        2'd1: pc_stall = rcn_stall[2] || pc_2_nop_loop;
        2'd2: pc_stall = rcn_stall[3] || pc_3_nop_loop;
        default: pc_stall = rcn_stall[0] || pc_0_nop_loop;
        endcase

        pc_inc = pc_next + 24'd1;
        pc_store_en = 1'b0;
        r7_push_en = 1'b0;
        pc_restore_en = 1'b0;

        if (idata[31:25] == 7'b1111111)
        begin
            r7_push_en = idata[24];
            pc_store_en = idata[24];
            pc_next = idata[23:0];
        end
        else if (idata[31:29] == 3'b110)
        begin
            if (idata[27] == 1'b0)
                pc_next = pc_next + {{12{idata[26]}}, idata[26:15]};
            else if (idata[22:15] == 8'd1)
            begin
                pc_restore_en = 1'b1;
                pc_next = pc_rtn;
            end
            else if (au_cond_true)
                pc_next = pc_next + {{16{idata[22]}}, idata[22:15]};
            else
                pc_next = pc_inc;
        end
        else
            pc_next = pc_inc;
    end

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            pc_sel <= 2'd0;
            instr_vld <= 1'b0;
            fetch_stall <= 1'b0;
            fetch_stall_d1 <= 1'b0;
        end
        else
        begin
            pc_sel <= pc_sel + 2'd1;
            instr_vld <= 1'b1;
            fetch_stall <= pc_stall;
            fetch_stall_d1 <= fetch_stall;
        end
      
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            pc <= 24'd0;
            pc_0 <= 24'd0;
            pc_1 <= 24'd1;
            pc_2 <= 24'd2;
            pc_3 <= 24'd3;
            pc_0_nop_loop <= 1'b0;
            pc_1_nop_loop <= 1'b0;
            pc_2_nop_loop <= 1'b0;
            pc_3_nop_loop <= 1'b0;
            series_cmd_0 <= 1'b0;
            series_cmd_1 <= 1'b0;
            series_cmd_2 <= 1'b0;
            series_cmd_3 <= 1'b0;
        end
        else if (~instr_vld)
            pc <= pc_1;
        else
        begin
            case (pc_sel[1:0])
            2'd0:
            begin
                pc <= pc_1;

                if (fetch_stall_d1)
                    pc_3 <= pc_3;
                else if (cmd_is_nop_loop)
                    pc_3_nop_loop <= 1'b1;
                else if (!idata[31] && !series_cmd_3)
                    series_cmd_3 <= 1'b1;
                else
                begin
                    pc_3 <= pc_next;
                    series_cmd_3 <= 1'b0;
                end
            end
      
            2'd1:
            begin
                pc <= pc_2;

                if (fetch_stall_d1)
                    pc_0 <= pc_0;
                else if (cmd_is_nop_loop)
                    pc_0_nop_loop <= 1'b1;
                else if (!idata[31] && !series_cmd_0)
                    series_cmd_0 <= 1'b1;
                else
                begin
                    pc_0 <= pc_next;
                    series_cmd_0 <= 1'b0;
                end
            end
      
            2'd2:
            begin
                pc <= pc_3;

                if (fetch_stall_d1)
                    pc_1 <= pc_1;
                else if (cmd_is_nop_loop)
                    pc_1_nop_loop <= 1'b1;
                else if (!idata[31] && !series_cmd_1)
                    series_cmd_1 <= 1'b1;
                else
                begin
                    pc_1 <= pc_next;
                    series_cmd_1 <= 1'b0;
                end
            end
      
            default:
            begin
                pc <= pc_0;

                if (fetch_stall_d1)
                    pc_2 <= pc_2;
                else if (cmd_is_nop_loop)
                    pc_2_nop_loop <= 1'b1;
                else if (!idata[31] && !series_cmd_2)
                    series_cmd_2 <= 1'b1;
                else
                begin
                    pc_2 <= pc_next;
                    series_cmd_2 <= 1'b0;
                end
            end
            endcase
        end

    //
    // Pick opcodes from instruction words
    //  

    reg au_upper;
    wire ls_upper;

    always @ *
    case (pc_sel[1:0])
    2'd0: au_upper = series_cmd_3;
    2'd1: au_upper = series_cmd_0;
    2'd2: au_upper = series_cmd_1;
    default: au_upper = series_cmd_2;
    endcase
  
    assign ls_upper = au_upper || (idata[31:30] == 2'b10);

    assign au_op_vld = !fetch_stall_d1 && ((idata[31:30] == 2'b00) || 
                       (idata[31:30] == 2'b10) || (idata[31:28] == 4'b1100));

    assign au_op = (au_upper) ? idata[30:15] : idata[14:0];

    assign rf_imm_vld = !fetch_stall_d1 && (idata[31:28] == 4'b1110);
    assign rf_imm_sel = idata[27:25];
    assign rf_imm = {{8{idata[24]}}, idata[23:0]};

    assign ls_dir_vld = !fetch_stall_d1 && (idata[31:27] == 5'b11110);
    assign ls_dir_store = idata[26];
    assign ls_dir_sel = idata[25:23];
    assign ls_dir_addr = {{8{idata[22]}}, idata[21:0], 2'd0};

    assign ls_op_vld = !fetch_stall_d1 && (r7_push_en ||
                       (idata[31:30] == 2'b01) || (idata[31:30] == 2'b10) || 
                       (idata[31:28] == 4'b1101));
    assign ls_op = (r7_push_en) ? {4'he, 5'h1f, 3'd6, 3'd7} : 
                     (ls_upper) ? idata[30:15] : idata[14:0];

endmodule
