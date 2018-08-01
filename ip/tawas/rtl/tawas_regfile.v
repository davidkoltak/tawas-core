/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas Register File
//

module tawas_regfile
(
    input clk,
    input rst,

    input thread_start_en,
    input [3:0] thread_start,

    output reg [255:0] regdata,
    output reg [7:0] au_flags,

    input [3:0] wb_thread,

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

    reg [263:0] regfile[15:0];

    always @ (posedge clk)
        if (thread_start_en) {au_flags, regdata} <= regfile[thread_start];

    wire wb_en_any = (wb_au_en || wb_ptr_en || wb_pc_en || wb_store_en || wb_bus_en);
    reg wen;
    reg [3:0] waddr;
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

    always (posedge clk or posedge rst)
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
