/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
    Debug State Capture

    Trigger captures the state of 3 x 32-bit words (96 bits total). A
    clock counter is started. Everytime the 96-bit input bits change
    an entry is made in the buffer with the previous state and how many
    clocks that state was detected.
    
    Addr
    0x000   : Control/Status
    0x004   : Live Input Data (32-bit Word 0)
    0x008   : Live Input Data (32-bit Word 1)
    0x00C   : Live Input Data (32-bit Word 2)
    0x010   : [Clock Count #0]
    0x014   : [Word0 #0]
    0x018   : [Word1 #0]
    0x01C   : [Word2 #0]
    0x020   : [Clock Count #1]
    0x024   : [Word0 #1]
    0x028   : [Word1 #1]
    0x02C   : [Word2 #1]
    (...)
              16-bytes per state detected. First word is "clock count".
              Next three words are state detected for the clock count.
    (...)
    0xFFF   :

    Control -
        [0]     Arm Trigger
        [1]     Force Trigger (Arm must also be set)
        [2]     Sample Done
        [3]     Sample Running
        [7-4]   RESERVED

        [15-8]  Mode (to debug target to select data/trigger settings)
        [31-16] RESERVED
*/

module rcn_debug_state
(
    input rcn_clk,
    input rcn_rst,

    input [68:0] rcn_in,
    output [68:0] rcn_out,

    output reg [7:0] lsa_mode,
    input lsa_clk,
    input lsa_trigger,
    input [95:0] lsa_data
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

    wire sample_running;
    reg rcn_running;
    reg lsa_running;
    
    wire [95:0] sample_live = lsa_data;
    reg [95:0] rcn_live;
    reg [95:0] lsa_live;

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
            {rcn_live, rcn_running, rcn_done, rcn_mode, rcn_force, rcn_arm} <=
                            {lsa_live, lsa_running, lsa_done, ctrl_mode, ctrl_force, ctrl_arm};

    always @ (posedge lsa_clk)
        if (sync_lsa == 2'b10)
            {lsa_live, lsa_running, lsa_done, lsa_mode, lsa_force, lsa_arm} <=
                            {sample_live, sample_running, sample_done, rcn_mode, rcn_force, rcn_arm};

    //
    // Sample state machine
    //

    reg [8:0] sample_waddr;
    assign sample_running = sample_waddr[8];
    reg [127:0] sample_data[255:0];
    reg [95:0] sample_state;
    reg [95:0] sample_state_d1;
    wire sample_next = (sample_state != sample_state_d1);
    reg [31:0] sample_cnt;

    always @ (posedge lsa_clk)
        sample_done <= lsa_arm && (sample_waddr == 8'd0);

    always @ (posedge lsa_clk)
        if (!lsa_arm)
            sample_waddr <= 9'h001;
        else if (!sample_waddr[8] && |sample_waddr[7:0])
            sample_waddr <= sample_waddr + 9'd1;
        else if (sample_waddr == 9'h100)
            sample_waddr <= (lsa_force || lsa_trigger) ? 9'h101 : 9'h100;
        else if (sample_next && (sample_waddr != 9'h000))
            sample_waddr <= sample_waddr + 9'd1;

    always @ (posedge lsa_clk)
    begin
        sample_state <= lsa_data;
        sample_state_d1 <= sample_state;
        sample_cnt <= (!sample_running || sample_next) ? 32'd1 :
                      (sample_cnt != 32'hFFFFFFFF) ? sample_cnt + 32'd1
                                                   : sample_cnt;
    end

    always @ (posedge lsa_clk)
        if (lsa_arm)
            sample_data[sample_waddr[7:0]] <= (sample_waddr[8]) ? {sample_state_d1, sample_cnt} : 96'd0;

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
            rcn_rdata <= {16'd0, ctrl_mode, 4'd0, rcn_running, rcn_done, ctrl_force, ctrl_arm};
        else if (rcn_addr[11:2] == 10'd1)
            rcn_rdata <= rcn_live[31:0];
        else if (rcn_addr[11:2] == 10'd2)
            rcn_rdata <= rcn_live[63:32];
        else if (rcn_addr[11:2] == 10'd3)
            rcn_rdata <= rcn_live[95:64];
        else if (rcn_addr[3:2] == 2'b00)
            rcn_rdata <= sample_data[rcn_addr[11:4]][31:0];
        else if (rcn_addr[3:2] == 2'b01)
            rcn_rdata <= sample_data[rcn_addr[11:4]][63:32];
        else if (rcn_addr[3:2] == 2'b10)
            rcn_rdata <= sample_data[rcn_addr[11:4]][95:64];
        else
            rcn_rdata <= sample_data[rcn_addr[11:4]][127:96];

endmodule
