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
    
    input [31:0] reg0,
    input [31:0] reg1,
    input [31:0] reg2,
    input [31:0] reg3,
    input [31:0] reg4,
    input [31:0] reg5,
    input [31:0] reg6,
    input [31:0] reg7,
    input [4:0] thread_decode,

    output [31:0] thread_mask,
    
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
    
    //
    // AU input registers
    //
    
    reg [32:0] reg_a;
    reg [32:0] reg_b;
    
    always @ (posedge clk)
        if (rf_imm_en)
        begin
            reg_a <= {rf_imm[31], rf_imm};
            reg_b <= 33'd0;
        end
        else if (au_op_en)
        begin
            case (au_op[2:0])
            3'd0: reg_a <= {1'b0, reg0};
            3'd1: reg_a <= {1'b0, reg1};
            3'd2: reg_a <= {1'b0, reg2};
            3'd3: reg_a <= {1'b0, reg3};
            3'd4: reg_a <= {1'b0, reg4};
            3'd5: reg_a <= {1'b0, reg5};
            3'd6: reg_a <= {1'b0, reg6};
            default: reg_a <= {1'b0, reg7};
            endcase
            
            case (au_op[5:3])
            3'd0: reg_b <= {1'b0, reg0};
            3'd1: reg_b <= {1'b0, reg1};
            3'd2: reg_b <= {1'b0, reg2};
            3'd3: reg_b <= {1'b0, reg3};
            3'd4: reg_b <= {1'b0, reg4};
            3'd5: reg_b <= {1'b0, reg5};
            3'd6: reg_b <= {1'b0, reg6};
            default: reg_b <= {1'b0, reg7};
            endcase
        end
    
    //
    // Pipeline commands
    //
    
    reg rf_imm_en_d1;
    reg [2:0] rf_imm_reg_d1;
    reg [14:0] au_op_d1;
    reg [4:0] csr_thread_id;
    
    always @ (posedge clk)
    begin
        rf_imm_en_d1 <= rf_imm_en;
        rf_imm_reg_d1 <= rf_imm_reg;
        au_op_d1 <= au_op;
        csr_thread_id <= thread_decode;
    end
    
    //
    // Shifters
    //
    
    wire [4:0] sh_bits = (au_op_d1[11]) ? au_op_d1[7:3] : reg_b[4:0];
    
    wire [31:0] sh_lsl = (reg_a[31:0] << sh_bits);
    wire [31:0] sh_lsr = (reg_a[31:0] >> sh_bits);
    wire [31:0] sh_asr = (reg_a[31:0] >>> sh_bits);
    
    //
    // Perform operation (step 1)
    //
    
    reg [2:0] wbreg_d2;
    reg [32:0] au_result_d2;

    reg [31:0] csr_thread_mask;
    reg [31:0] csr_ticks;
    reg [31:0] csr_scratch;
    
    assign thread_mask = csr_thread_mask;

    always @ (posedge clk or posedge rst)
        if (rst) csr_ticks <= 32'd0;
        else csr_ticks <= csr_ticks + 32'd1;
        
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            wbreg_d2 <= 3'd0;
            au_result_d2 <= 33'd0;
            csr_thread_mask <= 32'd1;
            csr_scratch <= 32'd0;
        end
        else if (rf_imm_en_d1)
        begin
            wbreg_d2 <= rf_imm_reg_d1;
            au_result_d2 <= reg_a;
        end
        else if (au_op_d1[14:13] == 2'b00)
        begin
            wbreg_d2 <= au_op_d1[8:6];
            case (au_op_d1[12:9])
            4'h0: au_result_d2 <= reg_a | reg_b;
            4'h1: au_result_d2 <= reg_a & reg_b;
            4'h2: au_result_d2 <= reg_a ^ reg_b;
            4'h3: au_result_d2 <= reg_a + reg_b;
            4'h4: au_result_d2 <= reg_a - reg_b;
            default: au_result_d2 <= 33'd0;
            endcase
        end
        else if (au_op_d1[14:11] == 4'b0100)
        begin
            wbreg_d2 <= au_op_d1[2:0];
            case (au_op_d1[10:6])
            5'h00: au_result_d2 <= ~reg_b;
            5'h01: au_result_d2 <= (~reg_b) + 33'd1;
            5'h02: au_result_d2 <= {{25{reg_b[7]}}, reg_b[7:0]};
            5'h03: au_result_d2 <= {{17{reg_b[15]}}, reg_b[15:0]};
            5'h04: au_result_d2 <= (|reg_b[31:5]) ? 33'd0 : {sh_lsl[31], sh_lsl};
            5'h05: au_result_d2 <= (|reg_b[31:5]) ? 33'd0 : {sh_lsr[31], sh_lsr};
            5'h06: au_result_d2 <= (|reg_b[31:5]) ? {33{reg_a[31]}}
                                                  : {sh_lsr[31], sh_asr};
            5'h1B:
                case (au_op_d1[5:3])
                3'd0: au_result_d2 <= {1'b0, RTL_VERSION};
                3'd1: au_result_d2 <= {28'd0, csr_thread_id};
                3'd2: au_result_d2 <= {1'b0, csr_thread_mask};
                3'd3: au_result_d2 <= {1'b0, csr_ticks};
                3'd7: au_result_d2 <= {1'b0, csr_scratch};
                default: au_result_d2 <= 33'd0;
                endcase
            // NO STORE 1C-1F ...
            5'h1D: au_result_d2 <= reg_a & reg_b;
            5'h1E: au_result_d2 <= reg_a - reg_b;
            5'h1F:
            begin
                au_result_d2 <= 33'd0;
                case (au_op_d1[5:3])
                3'd2: csr_thread_mask <= reg_a[31:0];
                3'd7: csr_scratch <= reg_a[31:0];
                default: ;
                endcase
            end
            default: au_result_d2 <= 33'd0;
            endcase
        end
        else if (au_op_d1[14:11] == 4'b0101)
        begin
            wbreg_d2 <= au_op_d1[2:0];
            case (au_op_d1[10:8])
            3'h0: au_result_d2 <= {32'd0, reg_a[au_op_d1[7:3]]};
            3'h1: au_result_d2 <= (reg_a & ~(33'd1 << au_op_d1[7:3]));
            3'h2: au_result_d2 <= (reg_a | (33'd1 << au_op_d1[7:3]));
            3'h3: au_result_d2 <= (reg_a ^ (33'd1 << au_op_d1[7:3]));
            3'h4: au_result_d2 <= {sh_lsl[31], sh_lsl};
            3'h5: au_result_d2 <= {sh_lsr[31], sh_lsr};
            3'h6: au_result_d2 <= {sh_asr[31], sh_asr};
            default: au_result_d2 <= 33'd0;
            endcase
        end
        else if (au_op_d1[14:12] == 3'b011)
        begin
            wbreg_d2 <= au_op_d1[2:0];
            au_result_d2 <= reg_a - {{24{au_op_d1[11]}}, au_op_d1[11:3]};
        end
        else if (au_op_d1[14:13] == 2'b10)
        begin
            wbreg_d2 <= au_op_d1[2:0];
            au_result_d2 <= reg_a + {{23{au_op_d1[12]}}, au_op_d1[12:3]};
        end
        else if (au_op_d1[14:13] == 2'b11)
        begin
            wbreg_d2 <= au_op_d1[2:0];
            au_result_d2 <= {{23{au_op_d1[12]}}, au_op_d1[12:3]};
        end
    
    //
    // Perform operation (step 2) - nothing to do
    //
    
    reg [32:0] au_result_d3;
    reg [2:0] wbreg_d3;
    
    always @ (posedge clk)
    begin
        wbreg_d3 <= wbreg_d2;
        au_result_d3 <= au_result_d2;
    end

    //
    // Store Result
    //
    
    reg wb_en_d1;
    reg wb_en_d2;
    reg wb_en_d3;
    
    wire no_store_op = (au_op[14:8] == 7'b0100111) || 
                       (au_op[14:12] == 3'b011) ||
                       (au_op_d1[14:8] == 7'b0101000);
    
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            wb_en_d1 <= 1'b0;
            wb_en_d2 <= 1'b0;
            wb_en_d3 <= 1'b0;
        end
        else
        begin
            wb_en_d1 <= rf_imm_en || (au_op_en && !no_store_op);
            wb_en_d2 <= wb_en_d1;
            wb_en_d3 <= wb_en_d2;
        end
    
    assign wb_au_en = wb_en_d3;
    assign wb_au_reg = wbreg_d3;
    assign wb_au_data = au_result_d3[31:0];

    //
    // Store flags
    //
    
    wire au_flag_zero = (au_result_d3 == 33'd0);
    wire au_flag_neg = au_result_d3[31];
    wire au_flag_ovfl = au_result_d3[32];
    
    assign wb_au_flags_en = wb_en_d3;
    assign wb_au_flags = {5'd0, au_flag_ovfl, au_flag_neg, au_flag_zero};
    
endmodule
