/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Tawas Load/Store:
//
// Perform load/store operations between the data bus and register file.
//

module tawas_ls
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

    input ls_dir_en,
    input ls_dir_store,
    input [2:0] ls_dir_reg,
    input [31:0] ls_dir_addr,
    
    input ls_op_en,
    input [14:0] ls_op,

    output reg dcs,
    output reg dwr,
    output reg [31:0] daddr,
    output reg [3:0] dmask,
    output reg [31:0] dout,
    input [31:0] din,

    output reg rcn_cs,
    output reg rcn_xch,
    output reg rcn_wr,
    output reg [31:0] rcn_addr,
    output reg [2:0] rcn_wbreg,
    output reg [3:0] rcn_mask,
    output reg [31:0] rcn_wdata,
        
    output wb_ptr_en,
    output [2:0] wb_ptr_reg,
    output [31:0] wb_ptr_data,

    output wb_store_en,
    output [2:0] wb_store_reg,
    output [31:0] wb_store_data
);

    //
    // Decode
    //
    
    wire ls_op_st = ls_op[14];
    wire ls_op_post_inc = ls_op[13];
    wire [1:0] ls_op_type = ls_op[12:11];
    wire [4:0] ls_op_off = ls_op[10:6];
    wire [2:0] ls_op_ptr = ls_op[5:3];
    wire [2:0] ls_op_reg = ls_op[2:0];
    
    wire wren = (ls_dir_en) ? ls_dir_store : ls_op_st;
    wire xchange = (ls_dir_en || !wren) ? 1'b0 : (ls_op_type == 2'b11);
    wire [2:0] wbreg = (ls_dir_en) ? ls_dir_reg : ls_op_reg;

    //
    // Bus address
    //
    
    reg [31:0] addr;
    reg [31:0] addr_inc;
    
    wire [31:0] bus_addr = (ls_dir_en || ls_op_post_inc) ? addr : addr_inc;
    wire data_bus_en = (ls_dir_en || ls_op_en) && (!bus_addr[31]);
    wire rcn_bus_en = (ls_dir_en || ls_op_en) && (bus_addr[31]);
    
    always @ *
        if (ls_dir_en)
        begin
            addr = ls_dir_addr;
            addr_inc = 32'd0;
        end
        else
        begin
            case (ls_op_ptr)
            3'd0: addr = reg0;
            3'd1: addr = reg1;
            3'd2: addr = reg2;
            3'd3: addr = reg3;
            3'd4: addr = reg4;
            3'd5: addr = reg5;
            3'd6: addr = reg6;
            default: addr = reg7;
            endcase
            
            case (ls_op_type)
            2'd0: addr = addr;
            2'd1: addr = addr & 32'hFFFFFFFE;
            default: addr = addr & 32'hFFFFFFFC;
            endcase
            
            case (ls_op_type)
            2'd0: addr_inc = addr + {{27{ls_op_off[4]}}, ls_op_off};
            2'd1: addr_inc = addr + {{26{ls_op_off[4]}}, ls_op_off, 1'b0};
            default: addr_inc = addr + {{25{ls_op_off[4]}}, ls_op_off, 2'd0};
            endcase
                       
        end
    
    //
    // Data/Mask
    //
    
    reg [31:0] wdata;
    reg [3:0] wmask;

    always @ *
        if (ls_dir_en)
        begin
            case (ls_dir_reg)
            3'd0: wdata = reg0;
            3'd1: wdata = reg1;
            3'd2: wdata = reg2;
            3'd3: wdata = reg3;
            3'd4: wdata = reg4;
            3'd5: wdata = reg5;
            3'd6: wdata = reg6;
            default: wdata = reg7;
            endcase
            
            wmask = 4'hF;
        end
        else
        begin
            case (ls_op_reg)
            3'd0: wdata = reg0;
            3'd1: wdata = reg1;
            3'd2: wdata = reg2;
            3'd3: wdata = reg3;
            3'd4: wdata = reg4;
            3'd5: wdata = reg5;
            3'd6: wdata = reg6;
            default: wdata = reg7;
            endcase

            case (ls_op_type)
            2'd0:
            begin
                wdata = {4{wdata[7:0]}};
                case (bus_addr[1:0])
                2'd0: wmask = 4'b0001;
                2'd1: wmask = 4'b0010;
                2'd2: wmask = 4'b0100;
                default: wmask = 4'b1000;
                endcase
            end
            2'd1:
            begin
                wdata = {2{wdata[15:0]}};
                if (!bus_addr[1])
                    wmask = 4'b0011;
                else
                    wmask = 4'b1100;
            end
            default: wmask = 4'hF;
            endcase
        end
    
    //
    // Issue bus transaction
    //
    
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            dcs <= 1'b0;
            rcn_cs <= 1'b0;
        end
        else
        begin
            dcs <= data_bus_en;
            rcn_cs <= rcn_bus_en;
        end
    
    always @ (posedge clk)
        if (data_bus_en)
        begin
            dwr <= wren;
            daddr <= bus_addr;
            dmask <= wmask;
            dout <= wdata;
        end
    
    always @ (posedge clk)
        if (rcn_bus_en)
        begin
            rcn_xch <= xchange;
            rcn_wr <= wren;
            rcn_addr <= bus_addr;
            rcn_wbreg <= wbreg;
            rcn_mask <= wmask;
            rcn_wdata <= wdata;
        end

    //
    // Retire data bus reads
    //
    
    reg ld_d1;
    reg ld_d2;
    reg ld_d3;

    reg wbptr_d1;
    reg wbptr_d2;
    reg wbptr_d3;
    
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            ld_d1 <= 1'b0;
            ld_d2 <= 1'b0;
            ld_d3 <= 1'b0;
            
            wbptr_d1 <= 1'b0;
            wbptr_d2 <= 1'b0;
            wbptr_d3 <= 1'b0;
        end
        else
        begin
            ld_d1 <= data_bus_en && (!wren || xchange);
            ld_d2 <= ld_d1;
            ld_d3 <= ld_d2;
            
            wbptr_d1 <= ls_op_en && ls_op_post_inc;
            wbptr_d2 <= wbptr_d1;
            wbptr_d3 <= wbptr_d2;
        end
    
    reg [2:0] wbreg_d1;
    reg [2:0] wbreg_d2;
    reg [2:0] wbreg_d3;
    
    reg [3:0] wmask_d1;
    reg [3:0] wmask_d2;
    reg [3:0] wmask_d3;
    
    reg [31:0] data_in;
    
    reg [2:0] wbptr_reg_d1;
    reg [2:0] wbptr_reg_d2;
    reg [2:0] wbptr_reg_d3;
    
    reg [31:0] wbptr_addr_d1;
    reg [31:0] wbptr_addr_d2;
    reg [31:0] wbptr_addr_d3;
    
    always @ (posedge clk)
    begin
        wbreg_d1 <= wbreg;
        wbreg_d2 <= wbreg_d1;
        wbreg_d3 <= wbreg_d2;
        
        wmask_d1 <= wmask;
        wmask_d2 <= wmask_d1;
        wmask_d3 <= wmask_d2;
        
        data_in <= din;
        
        wbptr_reg_d1 <= ls_op_ptr;
        wbptr_reg_d2 <= wbptr_reg_d1;
        wbptr_reg_d3 <= wbptr_reg_d2;
        
        wbptr_addr_d1 <= addr_inc;
        wbptr_addr_d2 <= wbptr_addr_d1;
        wbptr_addr_d3 <= wbptr_addr_d2;
    end
    
    reg [31:0] data_in_final;
    
    always @ *
        if (wmask_d3 == 4'b1111)
            data_in_final = data_in;
        else if (wmask_d3[1:0] == 2'b11)
            data_in_final = {16'd0, data_in[15:0]};
        else if (wmask_d3[3:2] == 2'b11)
            data_in_final = {16'd0, data_in[15:0]};
        else if (wmask_d3[0])
            data_in_final = {24'd0, data_in[7:0]};
        else if (wmask_d3[1])
            data_in_final = {24'd0, data_in[15:8]};
        else if (wmask_d3[2])
            data_in_final = {24'd0, data_in[23:16]};
        else
            data_in_final = {24'd0, data_in[31:24]};
    
    assign wb_ptr_en = wbptr_d3;
    assign wb_ptr_reg = wbptr_reg_d3;
    assign wb_ptr_data = wbptr_addr_d3;
    
    assign wb_store_en = ld_d3;
    assign wb_store_reg = wbreg_d3;
    assign wb_store_data = data_in_final;
    
endmodule

