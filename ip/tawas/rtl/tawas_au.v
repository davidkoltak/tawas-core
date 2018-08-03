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
    // Decode instruction
    //
    
    wire [3:0] au_mode = 4'hA;
    reg [3:0] au_mode_d1;
    reg [3:0] au_mode_d2;
    
    always @ (posedge clk)
    begin
        au_mode_d1 <= au_mode;
        au_mode_d2 <= au_mode_d1;
    end
    
    //
    // AU input registers
    //
    
    reg [31:0] reg_a;
    reg [31:0] reg_b;
    
    always @ (posedge clk)
        if (rf_imm_en)
        begin
            reg_a <= rf_imm;
            reg_b <= 32'd0;
        end
        else if (au_op_en)
        begin
            reg_a <= reg0;
            reg_b <= 32'd0;
        end
    
    //
    // Perform operation (step 1)
    //
    
    reg [31:0] au_result_d2;
    
    always @ (posedge clk)
        case (au_mode_d1)
        default: au_result_d2 <= reg_a;
        endcase
    
    //
    // Perform operation (step 2)
    //
    
    reg [31:0] au_result_d3;
    
    always @ (posedge clk)
        case(au_mode_d2)
        default: au_result_d3 <= au_result_d2;
        endcase

    //
    // Store Result
    //
    
    reg wb_en_d1;
    reg wb_en_d2;
    reg wb_en_d3;
    
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            wb_en_d1 <= 1'b0;
            wb_en_d2 <= 1'b0;
            wb_en_d3 <= 1'b0;
        end
        else
        begin
            wb_en_d1 <= rf_imm_en || au_op_en;
            wb_en_d2 <= wb_en_d1;
            wb_en_d3 <= wb_en_d2;
        end
        
    reg [2:0] wbreg_d1;
    reg [2:0] wbreg_d2;
    reg [2:0] wbreg_d3;
    
    always @ (posedge clk)
    begin
        wbreg_d1 <= (rf_imm_en) ? rf_imm_reg : 3'd0;
        wbreg_d2 <= wbreg_d1;
        wbreg_d3 <= wbreg_d2;
    end
    
    assign wb_au_en = wb_en_d3;
    assign wb_au_reg = wbreg_d3;
    assign wb_au_data = au_result_d3;

    //
    // Store flags
    //
    
    assign wb_au_flags_en = 1'b0;
    assign wb_au_flags = 8'd0;
    
endmodule
