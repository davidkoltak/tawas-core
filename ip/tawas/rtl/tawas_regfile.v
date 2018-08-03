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
    input [31:0] wb_store_data
);

    reg [263:0] regfile[31:0];
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

    wire wb_en_any = (wb_au_en || wb_au_flags_en || wb_ptr_en || wb_store_en);
    reg wen;
    reg [4:0] waddr;
    reg [255:0] wdata_calc;
    reg [255:0] wdata;
    reg [255:0] wmask_calc;
    reg [255:0] wmask;

    always @ *
    begin
        wdata_calc = 263'd0;
        wmask_calc = 263'd0;

        if (wb_au_en)
        begin
            wdata_calc = wdata_calc | ({232'd0, wb_au_data[31:0]} << (32 * wb_au_reg));
            wmask_calc = wmask_calc | ({232'd0, 32'hFFFFFFFF} << (32 * wb_au_reg));
        end

        if (wb_au_flags_en)
        begin
            wdata_calc = wdata_calc | {wb_au_flags, 256'd0};
            wmask_calc = wmask_calc | {8'hFF, 256'd0};
        end
        
        if (wb_ptr_en)
        begin
            wdata_calc = wdata_calc | ({232'd0, wb_ptr_data[31:0]} << (32 * wb_ptr_reg));
            wmask_calc = wmask_calc | ({232'd0, 32'hFFFFFFFF} << (32 * wb_ptr_reg));
        end

        if (wb_store_en)
        begin
            wdata_calc = wdata_calc | ({232'd0, wb_store_data[31:0]} << (32 * wb_store_reg));
            wmask_calc = wmask_calc | ({232'd0, 32'hFFFFFFFF} << (32 * wb_store_reg));
        end
    end

    always @ (posedge clk or posedge rst)
        if (rst) wen <= 1'b0;
        else wen <= wb_en_any;

    always @ (posedge clk)
        if (wb_en_any)
        begin
            waddr <= wb_thread;
            wdata <= wdata_calc;
            wmask <= wmask_calc;
        end

    always @ (posedge clk)
        if (wen) regfile[waddr] <= (regfile[waddr] & ~wmask) | wdata;

endmodule
