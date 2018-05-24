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

    input [1:0] slice,
    output [7:0] au_flags,

    input pc_restore,
    input [7:0] au_flags_rtn,

    input au_op_vld,
    input [14:0] au_op,

    output [3:0] au_ra_sel,
    input [31:0] au_ra,

    output [3:0] au_rb_sel,
    input [31:0] au_rb,

    output au_rc_vld,
    output [3:0] au_rc_sel,
    output [31:0] au_rc
);

    //
    // op decode
    //

    wire tworeg_vld;
    wire [3:0] tworeg_cmd;
    wire [3:0] reg_c_sel;

    wire bitop_vld;
    wire [2:0] bitop_cmd;
    wire [4:0] bitop_sel;

    wire imm_vld;
    wire [1:0] imm_cmd;
    wire [31:0] imm;

    assign tworeg_vld = au_op_vld && (au_op[14:13] == 2'b00);
    assign tworeg_cmd = (au_op[12]) ? {1'b0, au_op[11:9]} : au_op[11:8];

    assign bitop_vld = au_op_vld && (au_op[14:12] == 3'b010);
    assign bitop_cmd = au_op[11:9];
    assign bitop_sel = au_op[8:4];

    assign imm_vld = au_op_vld && (au_op[14] | (au_op[14:12] == 3'b011));
    assign imm_cmd = au_op[14:13];
    assign imm = (au_op[14]) ? {{23{au_op[12]}}, au_op[12:4]} : 
                               {{24{au_op[11]}}, au_op[11:4]};

    assign au_ra_sel = (au_op[14:12] == 3'b001) ? {1'b0, au_op[2:0]} : au_op[3:0];
    assign au_rb_sel = (au_op[14:12] == 3'b001) ? {1'b0, au_op[5:3]} : au_op[7:4];
    assign reg_c_sel = (au_op[14:12] == 3'b001) ? {1'b0, au_op[8:6]} : au_op[3:0];
    
    //
    // register stages
    //

    reg [31:0] reg_a_d1;
    reg [31:0] reg_b_d1;
    reg [3:0] tworeg_cmd_d1;
    reg [1:0] imm_cmd_d1;

    reg tworeg_vld_d1;
    reg bitop_vld_d1;
    reg imm_vld_d1;
    reg writeback_vld_d1;
    reg [3:0] reg_c_sel_d1;

    reg tworeg_vld_d2;
    reg bitop_vld_d2;
    reg imm_vld_d2;
    reg writeback_vld_d2;
    reg [3:0] reg_c_sel_d2;

    always @ (posedge clk)
        if (au_op_vld)
        begin
            reg_a_d1 <= au_ra;
            reg_b_d1 <= (imm_vld) ? imm : 
                        (bitop_vld) ? {24'd0, bitop_cmd, bitop_sel} : au_rb;
            tworeg_cmd_d1 <= tworeg_cmd;
            imm_cmd_d1 <= imm_cmd;  
        end

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            tworeg_vld_d1 <= 1'b0;
            bitop_vld_d1 <= 1'b0;
            imm_vld_d1 <= 1'b0;
            writeback_vld_d1 <= 1'b0;
            reg_c_sel_d1 <= 4'd0;

            tworeg_vld_d2 <= 1'b0;
            bitop_vld_d2 <= 1'b0;
            imm_vld_d2 <= 1'b0;
            writeback_vld_d2 <= 1'b0;
            reg_c_sel_d2 <= 4'd0;
        end
        else
        begin
            tworeg_vld_d1 <= tworeg_vld;
            bitop_vld_d1 <= bitop_vld;
            imm_vld_d1 <= imm_vld;
            writeback_vld_d1 <= (tworeg_vld && (tworeg_cmd != 4'hb)) || 
                                (bitop_vld && (bitop_cmd != 3'd2)) || 
                                (imm_vld && (imm_cmd != 2'd2));
            reg_c_sel_d1 <= reg_c_sel;

            tworeg_vld_d2 <= tworeg_vld_d1;
            bitop_vld_d2 <= bitop_vld_d1;
            imm_vld_d2 <= imm_vld_d1;
            writeback_vld_d2 <= writeback_vld_d1;
            reg_c_sel_d2 <= reg_c_sel_d1;
        end
  
    //
    // Generate AU results
    //

    reg [32:0] tworeg_result;

    always @ (posedge clk)
        if (tworeg_vld_d1)
            case (tworeg_cmd_d1)
            4'h0: tworeg_result <= {1'b0, reg_a_d1 | reg_b_d1};
            4'h1: tworeg_result <= {1'b0, reg_a_d1 & reg_b_d1};
            4'h2: tworeg_result <= {1'b0, reg_a_d1 ^ reg_b_d1};
            4'h3: tworeg_result <= {reg_a_d1[31], reg_a_d1} + {reg_b_d1[31], reg_b_d1};
            4'h4: tworeg_result <= {reg_a_d1[31], reg_a_d1} - {reg_b_d1[31], reg_b_d1};

            4'h8: tworeg_result <= {reg_b_d1[31], reg_b_d1};
            4'h9: tworeg_result <= ~{reg_b_d1[31], reg_b_d1};
            4'hA: tworeg_result <= 33'd1 + ~{reg_b_d1[31], reg_b_d1};
            4'hB: tworeg_result <= {reg_a_d1[31], reg_a_d1} - {reg_b_d1[31], reg_b_d1};

            default: tworeg_result <= 33'd0;
            endcase

    reg [32:0] bitop_result;
    wire [2:0] bitop_cmd_d1 = reg_b_d1[7:5];
    wire [4:0] bitop_sel_d1 = reg_b_d1[4:0];
    integer x;
  
    always @ (posedge clk)
        if (bitop_vld_d1)
            case (bitop_cmd_d1)
            3'd0: bitop_result <= {1'b0, reg_a_d1 | (32'd1 << bitop_sel_d1)};
            3'd1: bitop_result <= {1'b0, reg_a_d1 & ~(32'd1 << bitop_sel_d1)};
            3'd2: bitop_result <= {1'b0, reg_a_d1 & (32'd1 << bitop_sel_d1)};

            3'd4: bitop_result <= ({1'b0, reg_a_d1} << bitop_sel_d1);
            3'd5: bitop_result <= ({1'b0, reg_a_d1} >> bitop_sel_d1);
            3'd6: bitop_result <= ({reg_a_d1[31], reg_a_d1} >>> bitop_sel_d1);
            3'd7: 
            begin
                for (x = 0; x < bitop_sel_d1; x = x + 1)
                bitop_result[x] = reg_a_d1[x];
                for (x = bitop_sel_d1; x < 33; x = x + 1)
                bitop_result[x] = reg_a_d1[bitop_sel_d1];
            end    
            default: bitop_result <= 33'd0;
            endcase    
    
    reg [32:0] imm_result;

    always @ (posedge clk)
        if (imm_vld_d1)
            case (imm_cmd_d1)
            2'd1: imm_result <= {reg_a_d1[31], reg_a_d1} + {reg_b_d1[31], reg_b_d1};
            2'd2: imm_result <= {reg_a_d1[31], reg_a_d1} - {reg_b_d1[31], reg_b_d1};
            2'd3: imm_result <= {reg_b_d1[31], reg_b_d1};      
            default: imm_result <= 33'd0;
            endcase  
  
    //
    // send result back to register file
    //

    wire au_result_vld = imm_vld_d2 | bitop_vld_d2 | tworeg_vld_d2;
    wire [32:0] au_result = (imm_vld_d2) ? imm_result : 
                            (bitop_vld_d2) ? bitop_result : tworeg_result;

    assign au_rc_vld = writeback_vld_d2;
    assign au_rc_sel = reg_c_sel_d2;
    assign au_rc = au_result[31:0];

    //
    // select flags
    //

    reg [7:0] result_flags;
    reg [7:0] s0_flags;
    reg [7:0] s1_flags;
    reg [7:0] s2_flags;
    reg [7:0] s3_flags;
  
    always @ *
    begin
        case (slice[1:0])
        2'd0: result_flags = s1_flags;
        2'd1: result_flags = s2_flags;
        2'd2: result_flags = s3_flags;
        default: result_flags = s0_flags;
        endcase

        result_flags[0] = (au_result == 32'd0);             // zero
        result_flags[1] = au_result[31];                    // neg
        result_flags[2] = au_result[32] ^ au_result[31];    // ovfl
    end
  
    always @ (posedge clk or posedge rst)
        if (rst)
            s0_flags <= {3'b100, 5'd0};
        else if (au_result_vld && (slice == 2'd3))
            s0_flags <= result_flags;
        else if (pc_restore && (slice == 2'd1))
            s0_flags <= au_flags_rtn;

    always @ (posedge clk or posedge rst)
        if (rst)
            s1_flags <= {3'b101, 5'd0};
        else if (au_result_vld && (slice == 2'd0))
            s1_flags <= result_flags;
        else if (pc_restore && (slice == 2'd2))
            s1_flags <= au_flags_rtn;

    always @ (posedge clk or posedge rst)
        if (rst)
            s2_flags <= {3'b110, 5'd0};
        else if (au_result_vld && (slice == 2'd1))
            s2_flags <= result_flags;
        else if (pc_restore && (slice == 2'd3))
            s2_flags <= au_flags_rtn;

    always @ (posedge clk or posedge rst)
        if (rst)
            s3_flags <= {3'b111, 5'd0};
        else if (au_result_vld && (slice == 2'd2))
            s3_flags <= result_flags;
        else if (pc_restore && (slice == 2'd0))
            s3_flags <= au_flags_rtn;
      
    assign au_flags = (slice == 2'd3) ? s2_flags :
                      (slice == 2'd2) ? s1_flags :
                      (slice == 2'd1) ? s0_flags : s3_flags;
  
endmodule
