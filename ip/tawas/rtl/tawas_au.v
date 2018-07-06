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

    output [2:0] au_ra_sel,
    input [31:0] au_ra,

    output [2:0] au_rb_sel,
    input [31:0] au_rb,

    output au_rc_vld,
    output [2:0] au_rc_sel,
    output [31:0] au_rc
);
    parameter RTL_VERSION = 32'hFFFFFFFF;

    reg [15:0] op_d1;
    reg [15:0] op_d2;

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            op_d1 <= 16'd0;
            op_d2 <= 16'd0;
        end
        else
        begin
            op_d1 <= {au_op_vld, au_op};
            op_d2 <= (op_d1[14:0] == 15'd0) ? 16'd0 : op_d1;
        end

    assign au_ra_sel = au_op[2:0];
    assign au_rb_sel = au_op[5:3];
    assign au_rc_sel = (op_d2[14:13] == 2'b00) ? op_d2[8:6] : op_d2[2:0];

    wire no_store = (op_d2[14:7] == 8'b01001111) ||
                    (op_d2[14:8] == 7'b0101000) ||
                    (op_d2[14:12] == 3'b011);
    assign au_rc_vld = op_d2[15] && !no_store;

    reg [32:0] a_d1;
    reg [32:0] b_d1;

    reg [32:0] result;
    reg [31:0] interrupt[3:0];
    reg [31:0] scratch[3:0];
    reg [31:0] tick;
    wire [1:0] thread = slice + 2'd2;

    assign au_rc = result[31:0];

    always @ (posedge clk)
        a_d1 <= {au_ra[31], au_ra};

    always @ (posedge clk)
        b_d1 <= {au_rb[31], au_rb};

    always @ (posedge clk or posedge rst)
        if (rst)
            tick <= 32'd0;
        else if (slice == 2'b00)
            tick <= tick + 32'd1;

    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            result <= 33'd0;
            interrupt[0] <= 32'd0;
            interrupt[1] <= 32'd0;
            interrupt[2] <= 32'd0;
            interrupt[3] <= 32'd0;
            scratch[0] <= 32'd0;
            scratch[1] <= 32'd0;
            scratch[2] <= 32'd0;
            scratch[3] <= 32'd0;
        end
        else
            case (op_d1[14:13])
            2'b00:
            begin
                case (op_d1[12:9])
                4'b0000: result <= a_d1 | b_d1;
                4'b0001: result <= a_d1 & b_d1;
                4'b0010: result <= a_d1 ^ b_d1;
                4'b0011: result <= a_d1 + b_d1;
                4'b0100: result <= a_d1 - b_d1;
                default: result <= 33'd0;
                endcase
            end

            2'b01:
            begin
                if (op_d1[12])
                    result <= a_d1 - {{24{op_d1[11]}}, op_d1[11:3]};
                else if (op_d1[11])
                begin
                    case (op_d1[10:8])
                    3'b000: result <= a_d1 & {1'b0, (32'd1 << op_d1[7:3])};
                    3'b001: result <= a_d1 & ~{1'b0, (32'd1 << op_d1[7:3])};
                    3'b010: result <= a_d1 | {1'b0, (32'd1 << op_d1[7:3])};
                    3'b100: result <= (a_d1 << op_d1[7:3]);
                    3'b101: result <= ({1'b0, a_d1[31:0]} >> op_d1[7:3]);
                    3'b110: result <= (a_d1 >>> op_d1[7:3]);
                    default: result <= 33'd0;
                    endcase
                end
                else
                begin
                    case (op_d1[10:6])
                    5'b00000: result <= ~b_d1;
                    5'b00001: result <= (~b_d1) + 33'd1;
                    5'b00010: result <= {{24{b_d1[7]}}, b_d1[7:0]};
                    5'b00011: result <= {{16{b_d1[15]}}, b_d1[15:0]};

                    5'b11110: result = a_d1 - b_d1;

                    5'b01111:
                    begin
                        case (op_d1[5:3])
                        3'b000: result <= {1'b0, RTL_VERSION};
                        3'b001: result <= {31'd0, thread};
                        3'b010: result <= {1'b0, interrupt[thread]};
                        3'b011: result <= {1'b0, tick};
                        3'b111: result <= {1'b0, scratch[thread]};
                        default: result <= 33'd0;
                        endcase
                    end
                    5'b11111:
                    begin
                        case (op_d1[2:0])
                        3'b010: interrupt[thread] <= b_d1[31:0];
                        3'b111: scratch[thread] <= b_d1[31:0];
                        default: ;
                        endcase
                    end
                    default: result <= 33'd0;
                    endcase
                end
            end

            2'b10: result <= a_d1 + {{23{op_d1[12]}}, op_d1[12:3]};
            default: result <= {{23{op_d1[12]}}, op_d1[12:3]};
            endcase

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

        result_flags[0] = (result == 32'd0);          // zero
        result_flags[1] = result[31];                 // neg
        result_flags[2] = result[32] ^ result[31];    // ovfl
    end

    always @ (posedge clk or posedge rst)
        if (rst)
            s0_flags <= {3'b100, 5'd0};
        else if (op_d2[15] && (slice == 2'd3))
            s0_flags <= result_flags;
        else if (pc_restore && (slice == 2'd1))
            s0_flags <= au_flags_rtn;

    always @ (posedge clk or posedge rst)
        if (rst)
            s1_flags <= {3'b101, 5'd0};
        else if (op_d2[15] && (slice == 2'd0))
            s1_flags <= result_flags;
        else if (pc_restore && (slice == 2'd2))
            s1_flags <= au_flags_rtn;

    always @ (posedge clk or posedge rst)
        if (rst)
            s2_flags <= {3'b110, 5'd0};
        else if (op_d2[15] && (slice == 2'd1))
            s2_flags <= result_flags;
        else if (pc_restore && (slice == 2'd3))
            s2_flags <= au_flags_rtn;

    always @ (posedge clk or posedge rst)
        if (rst)
            s3_flags <= {3'b111, 5'd0};
        else if (op_d2[15] && (slice == 2'd2))
            s3_flags <= result_flags;
        else if (pc_restore && (slice == 2'd0))
            s3_flags <= au_flags_rtn;

    assign au_flags = (slice == 2'd3) ? s2_flags :
                      (slice == 2'd2) ? s1_flags :
                      (slice == 2'd1) ? s0_flags : s3_flags;

endmodule
