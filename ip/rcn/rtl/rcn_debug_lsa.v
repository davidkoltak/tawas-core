/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
    Debug Logic State Analyzer

    Addr
    0x000   : Control/Status
    0x004   : Live Input Data
    0x008   :
    (...)   : [Sample data, one per 'lsa_clk' with all 32-bits of input data]
    0xFFF   :

    Control -
        [0]     Arm Trigger
        [1]     Force Trigger (Arm must also be set)
        [2]     Sample Done
        [7-3]   RESERVED

        [15-8]  Mode (to debug target to select data/trigger settings)
*/

module rcn_debug_lsa
(
    input rcn_clk,
    input rcn_rst,

    input [68:0] rcn_in,
    output [68:0] rcn_out,

    output reg [7:0] lsa_mode,
    input lsa_clk,
    input lsa_trigger,
    input [31:0] lsa_data
);
    parameter ADDR_BASE = 1;   // 4kB window
    parameter INIT_ARMED = 1;
    parameter INIT_FORCED = 0;
    parameter INIT_MODE = 8'd0;

    wire rcn_cs;
    wire rcn_wr;
    wire [23:0] rcn_addr;
    wire [31:0] rcn_wdata;
    reg [31:0] rcn_rdata;
    
    rcn_slave #(.ADDR_BASE(ADDR_BASE), .ADDR_MASK(24'hFFF000)) rcn_slave
    (
        .rst(rcn_rst),
        .clk(rcn_clk),

        .rcn_in(rcn_in),
        .rcn_out(rcn_out),

        .cs(rcn_cs),
        .wr(rcn_wr),
        .mask(),
        .addr(rcn_addr),
        .wdata(rcn_wdata),
        .rdata(rcn_rdata)
    );
    
    //
    // Clock domain crossing
    //

    reg [1:0] sync_av;
    reg [1:0] sync_lsa;
    reg [1:0] sync_lsa_av;

    reg ctrl_arm;
    reg rcn_arm;
    reg lsa_arm;

    reg ctrl_force;
    reg rcn_force;
    reg lsa_force;

    reg [7:0] ctrl_mode;
    reg [7:0] rcn_mode;
    // lsa_mode in port list

    reg sample_done;
    reg rcn_done;
    reg lsa_done;

    wire [31:0] sample_live = lsa_data;
    reg [31:0] rcn_live;
    reg [31:0] lsa_live;

    always @ (posedge rcn_clk or posedge rcn_rst)
        if (rcn_rst)
        begin
            sync_lsa_av <= 2'd0;
            sync_av <= 2'd0;
        end
        else
        begin
            sync_lsa_av <= sync_lsa;
            sync_av <= (sync_lsa_av == sync_av) ? sync_av + 2'd1 : sync_av;
        end

    always @ (posedge lsa_clk)
        sync_lsa <= sync_av;

    always @ (posedge rcn_clk)
        if (sync_av == 2'b01)
            {rcn_live, rcn_done, rcn_mode, rcn_force, rcn_arm} <=
                            {lsa_live, lsa_done, ctrl_mode, ctrl_force, ctrl_arm};

    always @ (posedge lsa_clk)
        if (sync_lsa == 2'b10)
            {lsa_live, lsa_done, lsa_mode, lsa_force, lsa_arm} <=
                            {sample_live, sample_done, rcn_mode, rcn_force, rcn_arm};

    //
    // Sample state machine
    //

    reg [9:0] sample_waddr;
    reg [31:0] sample_data[1023:0];

    always @ (posedge lsa_clk)
        sample_done <= lsa_arm && (sample_waddr == 10'd0);

    always @ (posedge lsa_clk)
        if (!lsa_arm)
            sample_waddr <= 10'd1;
        else if (sample_waddr == 10'd1)
            sample_waddr <= (lsa_force || lsa_trigger) ? 10'd2 : 10'd1;
        else if (sample_waddr != 10'd0)
            sample_waddr <= sample_waddr + 10'd1;

    always @ (posedge lsa_clk)
        if (lsa_arm)
            sample_data[sample_waddr] <= lsa_data;

    //
    // Control register
    //

    reg init_cycle;
    
    always @ (posedge rcn_clk or posedge rcn_rst)
        if (rcn_rst)
        begin
            ctrl_arm <= 1'b0;
            ctrl_force <= 1'b0;
            ctrl_mode <= 8'd0;
            init_cycle <= 1'b0;
        end
        else if (!init_cycle)
        begin
            ctrl_arm <= (INIT_ARMED != 0);
            ctrl_force <= (INIT_FORCED != 0);
            ctrl_mode <= INIT_MODE;
            init_cycle <= 1'b1;
        end
        else if (rcn_cs && rcn_wr && (rcn_addr[11:2] == 10'd0))
        begin
            ctrl_arm <= rcn_wdata[0];
            ctrl_force <= rcn_wdata[1];
            ctrl_mode <= rcn_wdata[15:8];
        end

    always @ (posedge rcn_clk)
        if (rcn_addr[11:2] == 10'd0)
            rcn_rdata <= {16'd0, ctrl_mode, 5'd0, rcn_done, ctrl_force, ctrl_arm};
        else if (rcn_addr[11:2] == 10'd1)
            rcn_rdata <= rcn_live;
        else
            rcn_rdata <= sample_data[rcn_addr[11:2]];

endmodule
