/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * rcn direct memory access peripheral.
 *
 * Four DMA channels.
 * Each channel has four 32-bit registers: src, dst, ctrl, cnt.
 *
 * src, dst[21:0] = byte address
 *
 * crtl[3:0] = src req channel
 * ctrl[7:4] = dst req channel
 * crtl[8] = src increment
 * crtl[9] = dst increment
 * crtl[11:10] = transfer size (0=8-bit, 1=16-bit, 2=32-bit)
 *               NOTE: Addresses/Counts are aligned to transfer size
 * ctrl[12] = null terminate
 * ctrl[31] = channel done
 *
 * cnt[21:0] = byte count
 *
 * Set src and dst (byte addresses) first. Set ctrl as desired.
 * Write cnt (byte count) and wait for either "done" or (cnt == 0)
 *
 */

module rcn_dma
(
    input rst,
    input clk,

    input [68:0] rcn_in,
    output [68:0] rcn_out,

    input [15:0] req,
    output [3:0] done
);
    parameter MASTER_ID = 0;
    parameter ADDR_BASE = 0;

    wire [68:0] rcn_internal;

    wire slave_cs;
    wire slave_wr;
    wire [3:0] slave_mask;
    wire [23:0] slave_addr;
    wire [31:0] slave_wdata;
    reg [31:0] slave_rdata;

    wire slave_write = slave_cs && slave_wr;
    wire slave_read = slave_cs && !slave_wr;

    rcn_slave_fast #(.ADDR_MASK(24'hFFFFC0), .ADDR_BASE(ADDR_BASE)) rcn_slave
    (
        .rst(rst),
        .clk(clk),

        .rcn_in(rcn_in),
        .rcn_out(rcn_internal),

        .cs(slave_cs),
        .wr(slave_wr),
        .mask(slave_mask),
        .addr(slave_addr),
        .wdata(slave_wdata),
        .rdata(slave_rdata)
    );

    reg [23:0] src_addr_0;
    reg [23:0] dst_addr_0;
    reg [12:0] ctrl_0;
    reg [23:0] cnt_0;

    reg [23:0] src_addr_1;
    reg [23:0] dst_addr_1;
    reg [12:0] ctrl_1;
    reg [23:0] cnt_1;

    reg [23:0] src_addr_2;
    reg [23:0] dst_addr_2;
    reg [12:0] ctrl_2;
    reg [23:0] cnt_2;

    reg [23:0] src_addr_3;
    reg [23:0] dst_addr_3;
    reg [12:0] ctrl_3;
    reg [23:0] cnt_3;

    reg [3:0] status_done;
    assign done = status_done;

    reg [3:0] update;
    reg [3:0] null_trans;
    reg [23:0] next_src_addr;
    reg [23:0] next_dst_addr;
    reg [23:0] next_cnt;

    always @ (posedge clk or posedge rst)
        if (rst)
            src_addr_0 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h00))
            src_addr_0 <= slave_wdata[23:0];
        else if (update[0] && ctrl_0[8])
            src_addr_0 <= next_src_addr;

    always @ (posedge clk or posedge rst)
        if (rst)
            dst_addr_0 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h04))
            dst_addr_0 <= slave_wdata[23:0];
        else if (update[0] && ctrl_0[9])
            dst_addr_0 <= next_dst_addr;

    always @ (posedge clk or posedge rst)
        if (rst)
            ctrl_0 <= 13'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h08))
            ctrl_0 <= slave_wdata[12:0];

    always @ (posedge clk or posedge rst)
        if (rst)
            cnt_0 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h0C))
            cnt_0 <= slave_wdata[23:0];
        else if (null_trans[0] && ctrl_0[12])
            cnt_0 <= 24'd0;
        else if (update[0])
            cnt_0 <= next_cnt;

    always @ (posedge clk or posedge rst)
        if (rst)
            src_addr_1 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h10))
            src_addr_1 <= slave_wdata[23:0];
        else if (update[1] && ctrl_1[8])
            src_addr_1 <= next_src_addr;

    always @ (posedge clk or posedge rst)
        if (rst)
            dst_addr_1 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h14))
            dst_addr_1 <= slave_wdata[23:0];
        else if (update[1] && ctrl_1[9])
            dst_addr_1 <= next_dst_addr;

    always @ (posedge clk or posedge rst)
        if (rst)
            ctrl_1 <= 13'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h18))
            ctrl_1 <= slave_wdata[12:0];

    always @ (posedge clk or posedge rst)
        if (rst)
            cnt_1 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h1C))
            cnt_1 <= slave_wdata[23:0];
        else if (null_trans[1] && ctrl_1[12])
            cnt_1 <= 24'd0;
        else if (update[1])
            cnt_1 <= next_cnt;

    always @ (posedge clk or posedge rst)
        if (rst)
            src_addr_2 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h20))
            src_addr_2 <= slave_wdata[23:0];
        else if (update[2] && ctrl_2[8])
            src_addr_2 <= next_src_addr;

    always @ (posedge clk or posedge rst)
        if (rst)
            dst_addr_2 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h24))
            dst_addr_2 <= slave_wdata[23:0];
        else if (update[2] && ctrl_2[9])
            dst_addr_2 <= next_dst_addr;

    always @ (posedge clk or posedge rst)
        if (rst)
            ctrl_2 <= 13'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h28))
            ctrl_2 <= slave_wdata[12:0];

    always @ (posedge clk or posedge rst)
        if (rst)
            cnt_2 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h2C))
            cnt_2 <= slave_wdata[23:0];
        else if (null_trans[2] && ctrl_2[12])
            cnt_2 <= 24'd0;
        else if (update[2])
            cnt_2 <= next_cnt;

    always @ (posedge clk or posedge rst)
        if (rst)
            src_addr_3 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h30))
            src_addr_3 <= slave_wdata[23:0];
        else if (update[3] && ctrl_3[8])
            src_addr_3 <= next_src_addr;

    always @ (posedge clk or posedge rst)
        if (rst)
            dst_addr_3 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h34))
            dst_addr_3 <= slave_wdata[23:0];
        else if (update[3] && ctrl_3[9])
            dst_addr_3 <= next_dst_addr;

    always @ (posedge clk or posedge rst)
        if (rst)
            ctrl_3 <= 13'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h38))
            ctrl_3 <= slave_wdata[12:0];

    always @ (posedge clk or posedge rst)
        if (rst)
            cnt_3 <= 24'd0;
        else if (slave_write && (slave_addr[5:0] == 6'h3C))
            cnt_3 <= slave_wdata[23:0];
        else if (null_trans[3] && ctrl_3[12])
            cnt_3 <= 24'd0;
        else if (update[3])
            cnt_3 <= next_cnt;

    always @ *
        case (slave_addr[5:0])
        6'h00: slave_rdata = {8'd0, src_addr_0};
        6'h04: slave_rdata = {8'd0, dst_addr_0};
        6'h08: slave_rdata = {status_done[0], 18'd0, ctrl_0};
        6'h0C: slave_rdata = {8'd0, cnt_0};

        6'h10: slave_rdata = {8'd0, src_addr_1};
        6'h14: slave_rdata = {8'd0, dst_addr_1};
        6'h18: slave_rdata = {status_done[1], 18'd0, ctrl_1};
        6'h1C: slave_rdata = {8'd0, cnt_1};

        6'h20: slave_rdata = {8'd0, src_addr_2};
        6'h24: slave_rdata = {8'd0, dst_addr_2};
        6'h28: slave_rdata = {status_done[2], 18'd0, ctrl_2};
        6'h2C: slave_rdata = {8'd0, cnt_2};

        6'h30: slave_rdata = {8'd0, src_addr_3};
        6'h34: slave_rdata = {8'd0, dst_addr_3};
        6'h38: slave_rdata = {status_done[3], 18'd0, ctrl_3};
        6'h3C: slave_rdata = {8'd0, cnt_3};

        default: slave_rdata = 32'd0;
        endcase

    reg master_cs;
    reg [1:0] master_seq;
    wire master_busy;
    reg master_wr;
    reg [3:0] master_mask;
    reg [23:0] master_addr;
    reg [31:0] master_wdata;

    wire rdone;
    wire wdone;
    wire [1:0] rsp_seq;
    wire [3:0] rsp_mask;
    wire [31:0] rsp_data;

    rcn_master #(.MASTER_ID(MASTER_ID)) rcn_master
    (
        .rst(rst),
        .clk(clk),

        .rcn_in(rcn_internal),
        .rcn_out(rcn_out),

        .cs(master_cs),
        .seq(master_seq),
        .busy(master_busy),
        .wr(master_wr),
        .mask(master_mask),
        .addr(master_addr),
        .wdata(master_wdata),

        .rdone(rdone),
        .wdone(wdone),
        .rsp_seq(rsp_seq),
        .rsp_mask(rsp_mask),
        .rsp_addr(),
        .rsp_data(rsp_data)
    );

    reg [31:0] rdata_0;
    reg [31:0] rdata_1;
    reg [31:0] rdata_2;
    reg [31:0] rdata_3;

    wire [31:0] rsp_data_adj = (rsp_mask[3:0] == 4'b1111) ? rsp_data[31:0] :
                               (rsp_mask[3:2] == 2'b11) ? {2{rsp_data[31:16]}} :
                               (rsp_mask[1:0] == 2'b11) ? {2{rsp_data[15:0]}} :
                               (rsp_mask[3]) ? {4{rsp_data[31:24]}} :
                               (rsp_mask[2]) ? {4{rsp_data[23:16]}} :
                               (rsp_mask[1]) ? {4{rsp_data[15:8]}} : {4{rsp_data[7:0]}};

    always @ (posedge clk)
        if (rdone && (rsp_seq == 2'd0))
            rdata_0 <= rsp_data_adj;

    always @ (posedge clk)
        if (rdone && (rsp_seq == 2'd1))
            rdata_1 <= rsp_data_adj;

    always @ (posedge clk)
        if (rdone && (rsp_seq == 2'd2))
            rdata_2 <= rsp_data_adj;

    always @ (posedge clk)
        if (rdone && (rsp_seq == 2'd3))
            rdata_3 <= rsp_data_adj;

    reg [3:0] read_pending;
    reg [3:0] write_pending;

    wire [3:0] set_rpend = (master_cs && !master_wr && !master_busy) ? (4'd1 << master_seq) : 4'd0;
    wire [3:0] clr_rpend = (rdone) ? (4'd1 << rsp_seq) : 4'd0;

    always @ (posedge clk or posedge rst)
        if (rst)
            read_pending <= 4'd0;
        else
            read_pending <= (read_pending | set_rpend) & ~clr_rpend;

    wire [3:0] set_wpend = (master_cs && master_wr && !master_busy) ? (4'd1 << master_seq) : 4'd0;
    wire [3:0] clr_wpend = (wdone) ? (4'd1 << rsp_seq) : 4'd0;

    always @ (posedge clk or posedge rst)
        if (rst)
            write_pending <= 4'd0;
        else
            write_pending <= (write_pending | set_wpend) & ~clr_wpend;

    reg [1:0] state_0;
    reg [1:0] state_1;
    reg [1:0] state_2;
    reg [1:0] state_3;

    reg [1:0] chan_num;
    reg [3:0] chan_sel;
    reg [23:0] chan_src;
    reg [23:0] chan_dst;
    reg [11:0] chan_ctrl;
    reg [23:0] chan_cnt;
    reg chan_src_req;
    reg chan_dst_req;
    reg chan_rpend;
    reg chan_wpend;
    reg [31:0] chan_rdata;
    reg [1:0] chan_state;
    reg [1:0] chan_next_state;

    reg [3:0] chan_src_mask;
    reg [3:0] chan_dst_mask;

    reg [15:0] req_d1;

    always @ (posedge clk)
        req_d1 <= req;

    always @ *
        case (chan_num[1:0])
        2'd0:
        begin
            chan_sel = 4'b0001;
            chan_src = src_addr_0;
            chan_dst = dst_addr_0;
            chan_ctrl = ctrl_0;
            chan_cnt = cnt_0;
            chan_src_req = req_d1[ctrl_0[3:0]];
            chan_dst_req = req_d1[ctrl_0[7:4]];
            chan_rpend = read_pending[0];
            chan_wpend = write_pending[0];
            chan_rdata = rdata_0;
            chan_state = state_0;
        end
        2'd1:
        begin
            chan_sel = 4'b0010;
            chan_src = src_addr_1;
            chan_dst = dst_addr_1;
            chan_ctrl = ctrl_1;
            chan_cnt = cnt_1;
            chan_src_req = req_d1[ctrl_1[3:0]];
            chan_dst_req = req_d1[ctrl_1[7:4]];
            chan_rpend = read_pending[1];
            chan_wpend = write_pending[1];
            chan_rdata = rdata_1;
            chan_state = state_1;
        end
        2'd2:
        begin
            chan_sel = 4'b0100;
            chan_src = src_addr_2;
            chan_dst = dst_addr_2;
            chan_ctrl = ctrl_2;
            chan_cnt = cnt_2;
            chan_src_req = req_d1[ctrl_2[3:0]];
            chan_dst_req = req_d1[ctrl_2[7:4]];
            chan_rpend = read_pending[2];
            chan_wpend = write_pending[2];
            chan_rdata = rdata_2;
            chan_state = state_2;
        end
        default:
        begin
            chan_sel = 4'b1000;
            chan_src = src_addr_3;
            chan_dst = dst_addr_3;
            chan_ctrl = ctrl_3;
            chan_cnt = cnt_3;
            chan_src_req = req_d1[ctrl_3[3:0]];
            chan_dst_req = req_d1[ctrl_3[7:4]];
            chan_rpend = read_pending[3];
            chan_wpend = write_pending[3];
            chan_rdata = rdata_3;
            chan_state = state_3;
        end
        endcase

    always @ *
        case (chan_ctrl[11:10])
        2'd0: // 8-bit
        begin
            next_src_addr = chan_src + 24'd1;
            next_dst_addr = chan_dst + 24'd1;
            next_cnt = chan_cnt - 24'd1;

            case (chan_src[1:0])
            2'b00: chan_src_mask = 4'b0001;
            2'b01: chan_src_mask = 4'b0010;
            2'b10: chan_src_mask = 4'b0100;
            default: chan_src_mask = 4'b1000;
            endcase

            case (chan_dst[1:0])
            2'b00: chan_dst_mask = 4'b0001;
            2'b01: chan_dst_mask = 4'b0010;
            2'b10: chan_dst_mask = 4'b0100;
            default: chan_dst_mask = 4'b1000;
            endcase
        end
        2'd1: // 16-bit
        begin
            next_src_addr = (chan_src + 24'd2) & 24'hFFFFFE;
            next_dst_addr = (chan_dst + 24'd2) & 24'hFFFFFE;
            next_cnt = (chan_cnt - 24'd2) & 24'hFFFFFE;

            if (chan_src[1])
                chan_src_mask = 4'b1100;
            else
                chan_src_mask = 4'b0011;

            if (chan_dst[1])
                chan_dst_mask = 4'b1100;
            else
                chan_dst_mask = 4'b0011;
        end
        default: // 32-bit
        begin
            next_src_addr = (chan_src + 24'd4) & 24'hFFFFFC;
            next_dst_addr = (chan_dst + 24'd4) & 24'hFFFFFC;
            next_cnt = (chan_cnt - 24'd4) & 24'hFFFFFC;

            chan_src_mask = 4'b1111;
            chan_dst_mask = 4'b1111;
        end
        endcase

    always @ *
    begin
        chan_next_state = chan_state;
        master_cs = 1'b0;
        master_seq = 2'd0;
        master_wr = 1'b0;
        master_mask = 4'd0;
        master_addr = 24'd0;
        master_wdata = 32'd0;
        update = 4'd0;

        if (chan_cnt == 24'd0)
            chan_next_state = 3'd0;
        else
        begin
            case (chan_state)
            2'd0: // Read Request
            begin
                if (chan_src_req && !chan_rpend)
                begin
                    master_cs = 1'b1;
                    master_seq = chan_num;
                    master_wr = 1'b0;
                    master_mask = chan_src_mask;
                    master_addr = {chan_src[23:2], 2'b00};
                    if (!master_busy)
                        chan_next_state = chan_state + 2'd1;
                end
            end
            2'd1: // Write Request
            begin
                if (chan_dst_req && !chan_rpend && !chan_wpend)
                begin
                    master_cs = 1'b1;
                    master_seq = chan_num;
                    master_wr = 1'b1;
                    master_mask = chan_dst_mask;
                    master_addr = {chan_dst[23:2], 2'b00};
                    master_wdata = chan_rdata;
                    if (!master_busy)
                        chan_next_state = chan_state + 2'd1;
                end
            end
            2'd2: // Status Update
            begin
                null_trans = (chan_rdata == 32'd0) ? chan_sel : 4'd0;
                update = chan_sel;
                chan_next_state = 2'd0;
            end

            default: chan_next_state = 2'd0;
            endcase
        end
    end

    always @ (posedge clk or posedge rst)
        if (rst)
            chan_num <= 2'd0;
        else if (!read_pending[0] && (cnt_0 != 24'd0))
            chan_num <= 2'd0;
        else if (!read_pending[1] && (cnt_1 != 24'd0))
            chan_num <= 2'd1;
        else if (!read_pending[2] && (cnt_2 != 24'd0))
            chan_num <= 2'd2;
        else
            chan_num <= 2'd3;

    always @ (posedge clk or posedge rst)
        if (rst)
            state_0 <= 2'd0;
        else if (chan_sel[0])
            state_0 <= chan_next_state;

    always @ (posedge clk or posedge rst)
        if (rst)
            state_1 <= 2'd0;
        else if (chan_sel[1])
            state_1 <= chan_next_state;

    always @ (posedge clk or posedge rst)
        if (rst)
            state_2 <= 2'd0;
        else if (chan_sel[2])
            state_2 <= chan_next_state;

    always @ (posedge clk or posedge rst)
        if (rst)
            state_3 <= 2'd0;
        else if (chan_sel[3])
            state_3 <= chan_next_state;

    always @ (posedge clk)
    begin
        status_done[0] <= !read_pending[0] && !write_pending[0] && (cnt_0 == 24'd0);
        status_done[1] <= !read_pending[1] && !write_pending[1] && (cnt_1 == 24'd0);
        status_done[2] <= !read_pending[2] && !write_pending[2] && (cnt_2 == 24'd0);
        status_done[3] <= !read_pending[3] && !write_pending[3] && (cnt_3 == 24'd0);
    end

endmodule

