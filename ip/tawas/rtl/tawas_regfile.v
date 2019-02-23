/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas Register File
//

module tawas_regfile
(
    input clk,
    input rst,

    input thread_load_en,
    input [4:0] thread_load,

    output reg [31:0] reg0,
    output reg [31:0] reg1,
    output reg [31:0] reg2,
    output reg [31:0] reg3,
    output reg [31:0] reg4,
    output reg [31:0] reg5,
    output reg [31:0] reg6,
    output reg [31:0] reg7,
    output reg [7:0] au_flags,

    input [4:0] wb_thread,

    input wb_au_en,
    input [2:0] wb_au_reg,
    input [31:0] wb_au_data,

    input wb_au_flags_en,
    input [7:0] wb_au_flags,

    input wb_ptr_en,
    input [2:0] wb_ptr_reg,
    input [31:0] wb_ptr_data,

    input wb_store_en,
    input [2:0] wb_store_reg,
    input [31:0] wb_store_data,

    input rcn_load_en,
    input [4:0] rcn_load_thread,
    input [2:0] rcn_load_reg,
    input [31:0] rcn_load_data
);

    reg [31:0] regfile_0[31:0];
    reg [31:0] regfile_1[31:0];
    reg [31:0] regfile_2[31:0];
    reg [31:0] regfile_3[31:0];
    reg [31:0] regfile_4[31:0];
    reg [31:0] regfile_5[31:0];
    reg [31:0] regfile_6[31:0];
    reg [31:0] regfile_7[31:0];
    reg [7:0] regfile_au[31:0];

    //
    // Load register data
    //

    always @ (posedge clk)
        if (thread_load_en)
        begin
            reg0 <= regfile_0[thread_load];
            reg1 <= regfile_1[thread_load];
            reg2 <= regfile_2[thread_load];
            reg3 <= regfile_3[thread_load];
            reg4 <= regfile_4[thread_load];
            reg5 <= regfile_5[thread_load];
            reg6 <= regfile_6[thread_load];
            reg7 <= regfile_7[thread_load];
            au_flags <= regfile_au[thread_load];
        end

    //
    // Store register data
    //

    reg regfile_0_we;
    reg [4:0] regfile_0_sel;
    reg [31:0] regfile_0_data;

    always @ (posedge clk)
        if (wb_au_en && (wb_au_reg == 3'd0))
            {regfile_0_we, regfile_0_sel, regfile_0_data} <= {1'b1, wb_thread, wb_au_data};
        else if (wb_ptr_en && (wb_ptr_reg == 3'd0))
            {regfile_0_we, regfile_0_sel, regfile_0_data} <= {1'b1, wb_thread, wb_ptr_data};
        else if (wb_store_en && (wb_store_reg == 3'd0))
            {regfile_0_we, regfile_0_sel, regfile_0_data} <= {1'b1, wb_thread, wb_store_data};
        else if (rcn_load_en && (rcn_load_reg == 3'd0))
            {regfile_0_we, regfile_0_sel, regfile_0_data} <= {1'b1, rcn_load_thread, rcn_load_data};
        else
            regfile_0_we <= 1'b0;

    always @ (posedge clk)
        if (regfile_0_we)
            regfile_0[regfile_0_sel] <= regfile_0_data;


    reg regfile_1_we;
    reg [4:0] regfile_1_sel;
    reg [31:0] regfile_1_data;

    always @ (posedge clk)
        if (wb_au_en && (wb_au_reg == 3'd1))
            {regfile_1_we, regfile_1_sel, regfile_1_data} <= {1'b1, wb_thread, wb_au_data};
        else if (wb_ptr_en && (wb_ptr_reg == 3'd1))
            {regfile_1_we, regfile_1_sel, regfile_1_data} <= {1'b1, wb_thread, wb_ptr_data};
        else if (wb_store_en && (wb_store_reg == 3'd1))
            {regfile_1_we, regfile_1_sel, regfile_1_data} <= {1'b1, wb_thread, wb_store_data};
        else if (rcn_load_en && (rcn_load_reg == 3'd1))
            {regfile_1_we, regfile_1_sel, regfile_1_data} <= {1'b1, rcn_load_thread, rcn_load_data};
        else
            regfile_1_we <= 1'b0;

    always @ (posedge clk)
        if (regfile_1_we)
            regfile_1[regfile_1_sel] <= regfile_1_data;


    reg regfile_2_we;
    reg [4:0] regfile_2_sel;
    reg [31:0] regfile_2_data;

    always @ (posedge clk)
        if (wb_au_en && (wb_au_reg == 3'd2))
            {regfile_2_we, regfile_2_sel, regfile_2_data} <= {1'b1, wb_thread, wb_au_data};
        else if (wb_ptr_en && (wb_ptr_reg == 3'd2))
            {regfile_2_we, regfile_2_sel, regfile_2_data} <= {1'b1, wb_thread, wb_ptr_data};
        else if (wb_store_en && (wb_store_reg == 3'd2))
            {regfile_2_we, regfile_2_sel, regfile_2_data} <= {1'b1, wb_thread, wb_store_data};
        else if (rcn_load_en && (rcn_load_reg == 3'd2))
            {regfile_2_we, regfile_2_sel, regfile_2_data} <= {1'b1, rcn_load_thread, rcn_load_data};
        else
            regfile_2_we <= 1'b0;

    always @ (posedge clk)
        if (regfile_2_we)
            regfile_2[regfile_2_sel] <= regfile_2_data;


    reg regfile_3_we;
    reg [4:0] regfile_3_sel;
    reg [31:0] regfile_3_data;

    always @ (posedge clk)
        if (wb_au_en && (wb_au_reg == 3'd3))
            {regfile_3_we, regfile_3_sel, regfile_3_data} <= {1'b1, wb_thread, wb_au_data};
        else if (wb_ptr_en && (wb_ptr_reg == 3'd3))
            {regfile_3_we, regfile_3_sel, regfile_3_data} <= {1'b1, wb_thread, wb_ptr_data};
        else if (wb_store_en && (wb_store_reg == 3'd3))
            {regfile_3_we, regfile_3_sel, regfile_3_data} <= {1'b1, wb_thread, wb_store_data};
        else if (rcn_load_en && (rcn_load_reg == 3'd3))
            {regfile_3_we, regfile_3_sel, regfile_3_data} <= {1'b1, rcn_load_thread, rcn_load_data};
        else
            regfile_3_we <= 1'b0;

    always @ (posedge clk)
        if (regfile_3_we)
            regfile_3[regfile_3_sel] <= regfile_3_data;


    reg regfile_4_we;
    reg [4:0] regfile_4_sel;
    reg [31:0] regfile_4_data;

    always @ (posedge clk)
        if (wb_au_en && (wb_au_reg == 3'd4))
            {regfile_4_we, regfile_4_sel, regfile_4_data} <= {1'b1, wb_thread, wb_au_data};
        else if (wb_ptr_en && (wb_ptr_reg == 3'd4))
            {regfile_4_we, regfile_4_sel, regfile_4_data} <= {1'b1, wb_thread, wb_ptr_data};
        else if (wb_store_en && (wb_store_reg == 3'd4))
            {regfile_4_we, regfile_4_sel, regfile_4_data} <= {1'b1, wb_thread, wb_store_data};
        else if (rcn_load_en && (rcn_load_reg == 3'd4))
            {regfile_4_we, regfile_4_sel, regfile_4_data} <= {1'b1, rcn_load_thread, rcn_load_data};
        else
            regfile_4_we <= 1'b0;

    always @ (posedge clk)
        if (regfile_4_we)
            regfile_4[regfile_4_sel] <= regfile_4_data;


    reg regfile_5_we;
    reg [4:0] regfile_5_sel;
    reg [31:0] regfile_5_data;

    always @ (posedge clk)
        if (wb_au_en && (wb_au_reg == 3'd5))
            {regfile_5_we, regfile_5_sel, regfile_5_data} <= {1'b1, wb_thread, wb_au_data};
        else if (wb_ptr_en && (wb_ptr_reg == 3'd5))
            {regfile_5_we, regfile_5_sel, regfile_5_data} <= {1'b1, wb_thread, wb_ptr_data};
        else if (wb_store_en && (wb_store_reg == 3'd5))
            {regfile_5_we, regfile_5_sel, regfile_5_data} <= {1'b1, wb_thread, wb_store_data};
        else if (rcn_load_en && (rcn_load_reg == 3'd5))
            {regfile_5_we, regfile_5_sel, regfile_5_data} <= {1'b1, rcn_load_thread, rcn_load_data};
        else
            regfile_5_we <= 1'b0;

    always @ (posedge clk)
        if (regfile_5_we)
            regfile_5[regfile_5_sel] <= regfile_5_data;


    reg regfile_6_we;
    reg [4:0] regfile_6_sel;
    reg [31:0] regfile_6_data;

    always @ (posedge clk)
        if (wb_au_en && (wb_au_reg == 3'd6))
            {regfile_6_we, regfile_6_sel, regfile_6_data} <= {1'b1, wb_thread, wb_au_data};
        else if (wb_ptr_en && (wb_ptr_reg == 3'd6))
            {regfile_6_we, regfile_6_sel, regfile_6_data} <= {1'b1, wb_thread, wb_ptr_data};
        else if (wb_store_en && (wb_store_reg == 3'd6))
            {regfile_6_we, regfile_6_sel, regfile_6_data} <= {1'b1, wb_thread, wb_store_data};
        else if (rcn_load_en && (rcn_load_reg == 3'd6))
            {regfile_6_we, regfile_6_sel, regfile_6_data} <= {1'b1, rcn_load_thread, rcn_load_data};
        else
            regfile_6_we <= 1'b0;

    always @ (posedge clk)
        if (regfile_6_we)
            regfile_6[regfile_6_sel] <= regfile_6_data;


    reg regfile_7_we;
    reg [4:0] regfile_7_sel;
    reg [31:0] regfile_7_data;

    always @ (posedge clk)
        if (wb_au_en && (wb_au_reg == 3'd7))
            {regfile_7_we, regfile_7_sel, regfile_7_data} <= {1'b1, wb_thread, wb_au_data};
        else if (wb_ptr_en && (wb_ptr_reg == 3'd7))
            {regfile_7_we, regfile_7_sel, regfile_7_data} <= {1'b1, wb_thread, wb_ptr_data};
        else if (wb_store_en && (wb_store_reg == 3'd7))
            {regfile_7_we, regfile_7_sel, regfile_7_data} <= {1'b1, wb_thread, wb_store_data};
        else if (rcn_load_en && (rcn_load_reg == 3'd7))
            {regfile_7_we, regfile_7_sel, regfile_7_data} <= {1'b1, rcn_load_thread, rcn_load_data};
        else
            regfile_7_we <= 1'b0;

    always @ (posedge clk)
        if (regfile_7_we)
            regfile_7[regfile_7_sel] <= regfile_7_data;


    always @ (posedge clk)
        if (wb_au_flags_en)
            regfile_au[wb_thread] <= wb_au_flags;

endmodule
