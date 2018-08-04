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
            3'd0: reg_a <= {reg0[31], reg0};
            3'd1: reg_a <= {reg1[31], reg1};
            3'd2: reg_a <= {reg2[31], reg2};
            3'd3: reg_a <= {reg3[31], reg3};
            3'd4: reg_a <= {reg4[31], reg4};
            3'd5: reg_a <= {reg5[31], reg5};
            3'd6: reg_a <= {reg6[31], reg6};
            default: reg_a <= {reg7[31], reg7};
            endcase
            
            case (au_op[5:3])
            3'd0: reg_b <= {reg0[31], reg0};
            3'd1: reg_b <= {reg1[31], reg1};
            3'd2: reg_b <= {reg2[31], reg2};
            3'd3: reg_b <= {reg3[31], reg3};
            3'd4: reg_b <= {reg4[31], reg4};
            3'd5: reg_b <= {reg5[31], reg5};
            3'd6: reg_b <= {reg6[31], reg6};
            default: reg_b <= {reg7[31], reg7};
            endcase
        end
    
    //
    // Pipeline commands
    //
    
    reg rf_imm_en_d1;
    reg [2:0] rm_imm_reg_d1;
    reg [14:0] au_op_d1;
    
    always @ (posedge clk)
    begin
        rf_imm_en_d1 <= rm_imm_en;
        rf_imm_reg_d1 <= rf_imm_reg;
        au_op_d1 <= au_op;
    end
    
    //
    // Perform operation (step 1)
    //
    
    reg [2:0] wbreg_d2;
    reg [32:0] au_result_d2;
    
    always @ (posedge clk)
        if (rf_imm_en_d1)
        begin
            wbreg_d2 <= rf_imm_reg_d1;
            au_result_d2 <= reg_a;
        end
        else if (au_op_d1[14:13] == 2'b00)
        begin
            wbreg_d1 <= au_op_d1[8:6];
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
            wbreg_d1 <= au_op_d1[2:0];
            case (au_op_d1[10:6])
            5'h00: au_result_d2 <= ~reg_b;
            5'h01: au_result_d2 <= (~reg_b) + 33'd1;
            5'h02: au_result_d2 <= {{25{reg_b[7]}}, reg_b[7:0]};
            5'h03: au_result_d2 <= {{17{reg_b[15]}}, reg_b[15:0]};
            5'h1E: au_result_d2 <= reg_a & reg_b;
            5'h1F: au_result_d2 <= reg_a - reg_b;
            default: au_result_d2 <= 33'd0;
            endcase
        end
        else if (au_op_d1[14:11] == 4'b0101)
        begin
            wbreg_d1 <= au_op_d1[2:0];
            case (au_op_d1[10:8])
            3'h0: au_result_d2 <= (reg_a & ~(33'd1 << au_op[7:3]));
            3'h1: au_result_d2 <= (reg_a | (33'd1 << au_op[7:3]));
            4'h4: au_result_d2 <= (reg_a << au_op[7:3]);
            4'h5: au_result_d2 <= (reg_a >> au_op[7:3]);
            4'h6: au_result_d2 <= (reg_a >>> au_op[7:3]);
            default: au_result_d2 <= 33'd0;
            endcase
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
    
    wire no_store_op = (au_op[14:10] == 5'h09) || (au_op[14:12] == 3'd011);
    
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
    
    assign wb_au_flags_en = 1'b0;
    assign wb_au_flags = 8'd0;
    
endmodule
