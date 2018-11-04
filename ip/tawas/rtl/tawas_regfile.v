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
    
    output [31:0] reg0,
    output [31:0] reg1,
    output [31:0] reg2,
    output [31:0] reg3,
    output [31:0] reg4,
    output [31:0] reg5,
    output [31:0] reg6,
    output [31:0] reg7,
    output [7:0] au_flags,

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

    reg [263:0] regfile[31:0];
    
    //
    // Load register data
    //

    reg [263:0] regdata;
    
    assign reg0 = regdata[31:0];
    assign reg1 = regdata[63:32];
    assign reg2 = regdata[95:64];
    assign reg3 = regdata[127:96];
    assign reg4 = regdata[159:128];
    assign reg5 = regdata[191:160];
    assign reg6 = regdata[223:192];
    assign reg7 = regdata[255:224];
    assign au_flags = regdata[263:256];
    
    always @ (posedge clk)
        if (thread_load_en) regdata <= regfile[thread_load];

    //
    // Create au/flags/ptr/store writeback data/mask vectors
    //
    
    reg [263:0] wdata_au;
    reg [263:0] wmask_au;
    reg [263:0] wdata_flags;
    reg [263:0] wmask_flags;
    reg [263:0] wdata_ptr;
    reg [263:0] wmask_ptr;
    reg [263:0] wdata_store;
    reg [263:0] wmask_store;
    
    always @ *
        if (wb_au_en)
        begin
            wdata_au = ({8'd0, {7{32'd0}}, wb_au_data[31:0]} << (32 * wb_au_reg));
            wmask_au = ({8'd0, {7{32'd0}}, 32'hFFFFFFFF} << (32 * wb_au_reg));
        end
        else
        begin
            wdata_au = {8'd0, {8{32'd0}}};
            wmask_au = {8'd0, {8{32'd0}}};
        end

    always @ *
        if (wb_au_flags_en)
        begin
            wdata_flags = {wb_au_flags, {8{32'd0}}};
            wmask_flags = {8'hFF, {8{32'd0}}};
        end
        else
        begin
            wdata_flags = {8'd0, {8{32'd0}}};
            wmask_flags = {8'd0, {8{32'd0}}};
        end
        
    always @ *
        if (wb_ptr_en)
        begin
            wdata_ptr = ({8'd0, {7{32'd0}}, wb_ptr_data[31:0]} << (32 * wb_ptr_reg));
            wmask_ptr = ({8'd0, {7{32'd0}}, 32'hFFFFFFFF} << (32 * wb_ptr_reg));
        end
        else
        begin
            wdata_ptr = {8'd0, {8{32'd0}}};
            wmask_ptr = {8'd0, {8{32'd0}}};
        end

    always @ *
        if (wb_store_en)
        begin
            wdata_store = ({8'd0, {7{32'd0}}, wb_store_data[31:0]} << (32 * wb_store_reg));
            wmask_store = ({8'd0, {7{32'd0}}, 32'hFFFFFFFF} << (32 * wb_store_reg));
        end
        else
        begin
            wdata_store = {8'd0, {8{32'd0}}};
            wmask_store = {8'd0, {8{32'd0}}};
        end

    //
    // Delay RCN load until writeback window
    //
    
    reg rcn_load_en_d1;
    reg rcn_load_en_d2;
    reg [4:0] rcn_load_thread_d1;
    reg [4:0] rcn_load_thread_d2;
    reg [2:0] rcn_load_reg_d1;
    reg [2:0] rcn_load_reg_d2;
    reg [31:0] rcn_load_data_d1;
    reg [31:0] rcn_load_data_d2;
    reg [263:0] wdata_rcn;
    reg [263:0] wmask_rcn;
    
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            rcn_load_en_d1 <= 1'b0;
            rcn_load_en_d2 <= 1'b0;
        end
        else
        begin
            rcn_load_en_d1 <= rcn_load_en;
            rcn_load_en_d2 <= rcn_load_en_d1;
        end
    
    always @ (posedge clk)
        begin
            rcn_load_thread_d1 <= rcn_load_thread;
            rcn_load_thread_d2 <= rcn_load_thread_d1;
            rcn_load_reg_d1 <= rcn_load_reg;
            rcn_load_reg_d2 <= rcn_load_reg_d1;
            rcn_load_data_d1 <= rcn_load_data;
            rcn_load_data_d2 <= rcn_load_data_d1;
        end

    always @ *
        if (rcn_load_en_d2)
        begin
            wdata_rcn = ({8'd0, {7{32'd0}}, rcn_load_data_d2[31:0]} << (32 * rcn_load_reg_d2));
            wmask_rcn = ({8'd0, {7{32'd0}}, 32'hFFFFFFFF} << (32 * rcn_load_reg_d2));
        end
        else
        begin
            wdata_rcn = {8'd0, {8{32'd0}}};
            wmask_rcn = {8'd0, {8{32'd0}}};
        end

    //
    // Combine all writes
    //
    
    reg wen;
    wire wb_en_any = (wb_au_en || wb_au_flags_en || wb_ptr_en || wb_store_en || rcn_load_reg_d2);
    reg [4:0] waddr;
    reg [263:0] wdata;
    reg [263:0] wmask;
    
    always @ (posedge clk or posedge rst)
        if (rst) wen <= 1'b0;
        else wen <= wb_en_any;

    always @ (posedge clk)
        if (wb_en_any)
        begin
            waddr <= (rcn_load_thread_d2) ? rcn_load_thread_d2 : wb_thread;
            wdata <= wdata_au | wdata_flags | wdata_ptr | wdata_store | wdata_rcn;
            wmask <= wmask_au | wmask_flags | wmask_ptr | wmask_store | wmask_rcn;
        end

    always @ (posedge clk)
        if (wen) regfile[waddr] <= (regfile[waddr] & ~wmask) | wdata;

endmodule
