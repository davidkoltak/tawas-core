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

    output reg dcs,
    output reg dwr,
    output reg [31:0] daddr,
    output reg [2:0] writeback_reg,
    output reg [3:0] dmask,
    output reg [31:0] dout,
    input [31:0] din,

    output rcn_cs,
    output rcn_xch,
    output rcn_wr,
    output [31:0] rcn_addr,
    output [2:0] rcn_wbreg,
    output [3:0] rcn_mask,
    output [31:0] rcn_wdata,

    input ls_op_vld,
    input [14:0] ls_op,

    input ls_dir_vld,
    input ls_dir_store,
    input [2:0] ls_dir_sel,
    input [31:0] ls_dir_addr,

    output [2:0] ls_ptr_sel,
    input [31:0] ls_ptr,

    output [2:0] ls_store_sel,
    input [31:0] ls_store,

    output reg ls_ptr_upd_vld,
    output reg [2:0] ls_ptr_upd_sel,
    output reg [31:0] ls_ptr_upd,

    output ls_load_vld,
    output [2:0] ls_load_sel,
    output [31:0] ls_load
);

    //
    // Instruction decode
    //

    reg [7:0] ld_d1;
    reg [7:0] ld_d2;
    reg [7:0] ld_d3;

    wire rcn_space;
    wire [31:0] addr_offset;
    wire [31:0] addr_adj;
    wire [31:0] addr_next;
    wire [31:0] addr_out;

    wire [2:0] data_reg;

    wire wr_en;
    wire xch_en;
    wire [31:0] wr_data;
    wire [3:0] data_mask;

    assign data_reg = (ls_dir_vld) ? ls_dir_sel : ls_op[2:0];

    assign ls_ptr_sel = ls_op[5:3];
    assign ls_store_sel = data_reg;

    assign addr_offset = (ls_op[12]) ? {{25{1'b0}}, ls_op[10:6], 2'd0} :
                         (ls_op[11]) ? {{26{1'b0}}, ls_op[10:6], 1'd0}
                                     : {{27{1'b0}}, ls_op[10:6]};

    assign addr_adj = (ls_op[12]) ? {{25{ls_op[10]}}, ls_op[10:6], 2'd0} :
                      (ls_op[11]) ? {{26{ls_op[10]}}, ls_op[10:6], 1'd0}
                                  : {{27{ls_op[10]}}, ls_op[10:6]};

    assign addr_next = ls_ptr + ((ls_op[13]) ? addr_adj : addr_offset);
    assign addr_out = (ls_dir_vld) ? ls_dir_addr :
                      (ls_op[13] && !addr_adj[31]) ? ls_ptr : addr_next;

    assign rcn_space = addr_out[31];

    assign wr_en = (ls_dir_vld && ls_dir_store) || (ls_op_vld && ls_op[14]);
    assign xch_en = ls_op_vld && ls_op[14] && (ls_op[12:11] == 2'b11);

    assign wr_data = (ls_op[12] || ls_dir_vld) ? ls_store[31:0] :
                     (ls_op[11]) ? {ls_store[15:0], ls_store[15:0]}
                                 : {ls_store[7:0], ls_store[7:0], ls_store[7:0], ls_store[7:0]};

    assign data_mask = (ls_op[12] || ls_dir_vld) ? 4'b1111 :
                       (ls_op[11]) ? (addr_out[1]) ? 4'b1100 : 4'b0011
                                   : (addr_out[1] && addr_out[0]) ? 4'b1000 :
                                     (addr_out[1]               ) ? 4'b0100 :
                                     (               addr_out[0]) ? 4'b0010
                                                                  : 4'b0001;

    //
    // Update pointers
    //

    always @ (posedge clk)
        if (ls_op_vld)
        begin
            ls_ptr_upd_vld <= ls_op[13];
            ls_ptr_upd_sel <= ls_op[5:3];
            ls_ptr_upd <= addr_next;
        end
        else
        begin
            ls_ptr_upd_vld <= 1'b0;
            ls_ptr_upd_sel <= 3'b0;
            ls_ptr_upd <= 32'd0;
        end

    //
    // Send no-wait bus request
    //

    always @ (posedge clk or posedge rst)
        if (rst)
            ld_d1 <= 8'd0;
        else if (ls_op_vld || ls_dir_vld)
            ld_d1 <= {(!wr_en || xch_en) && !rcn_space, 
                      (ls_dir_vld) ? 2'b10 : ls_op[12:11], 
                      addr_out[1:0], data_reg};
        else
            ld_d1 <= 8'd0;

    always @ (posedge clk or posedge rst)
        if (rst)
            {ld_d3, ld_d2} <= {8'd0, 8'd0};
        else
            {ld_d3, ld_d2} <= {ld_d2, ld_d1};

    always @ (posedge clk)
        if (ls_op_vld || ls_dir_vld)
        begin
            daddr <= {addr_out[31:2], 2'b00};
            dcs <=  !rcn_space;
            writeback_reg <= data_reg;
            dwr <= wr_en;
            dmask <= data_mask;
            dout <= (wr_en) ? wr_data : 32'd0;
        end
        else
        begin
            daddr <= 32'd0;
            dcs <= 1'b0;
            writeback_reg <= 3'd0;
            dwr <= 1'b0;
            dmask <= 4'b0000;
            dout <= 32'd0;
        end

    //
    // RCN interface
    //

    assign rcn_cs = rcn_space && (ls_op_vld || ls_dir_vld);
    assign rcn_xch = xch_en;
    assign rcn_wr = wr_en;
    assign rcn_addr = {addr_out[31:2], 2'b00};
    assign rcn_wbreg = data_reg;
    assign rcn_mask = data_mask;
    assign rcn_wdata = wr_data;

    //
    // Register no-wait read data (D BUS) and send to regfile
    //

    reg [31:0] rd_data;
    wire [31:0] rd_data_final;

    always @ (posedge clk)
        if (ld_d2[7])
            rd_data <= din;

    assign rd_data_final = (ld_d3[6]) ? rd_data :
                     (ld_d3[5]) ? (ld_d3[4]) ? {16'd0, rd_data[31:16]}
                                             : {16'd0, rd_data[15:0]}
                                : (ld_d3[4] && ld_d3[3]) ? {24'd0, rd_data[31:24]} :
                                  (ld_d3[4]            ) ? {24'd0, rd_data[23:16]} :
                                  (            ld_d3[3]) ? {24'd0, rd_data[15:8]}
                                                         : {24'd0, rd_data[7:0]};

    assign ls_load_vld = ld_d3[7];
    assign ls_load_sel = ld_d3[2:0];
    assign ls_load = rd_data_final;

endmodule

