
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
        [3]     Sample Running
        [7-4]   RESERVED

        [15-8]  Mode (to debug target to select data/trigger settings)
        [31-16] RESERVED
*/

module debug_lsa
(
    input av_clk,
    input av_rst,

    input [9:0] av_address,
    input av_write,
    input av_read,
    input [31:0] av_writedata,
    output reg [31:0] av_readdata,
    output reg av_readdatavalid,

    output reg [7:0] lsa_mode,
    input lsa_clk,
    input lsa_trigger,
    input [31:0] lsa_data
);
    parameter INIT_ARMED = 1;
    parameter INIT_FORCED = 0;
    parameter INIT_MODE = 8'd0;

    //
    // Clock domain crossing
    //

    reg [1:0] sync_av;
    reg [1:0] sync_lsa;
    reg [1:0] sync_lsa_av;

    reg ctrl_arm;
    reg av_arm;
    reg lsa_arm;

    reg ctrl_force;
    reg av_force;
    reg lsa_force;

    reg [7:0] ctrl_mode;
    reg [7:0] av_mode;
    // lsa_mode in port list

    reg sample_done;
    reg av_done;
    reg lsa_done;

    wire sample_running;
    reg av_running;
    reg lsa_running;

    wire [31:0] sample_live = lsa_data;
    reg [31:0] av_live;
    reg [31:0] lsa_live;

    always @ (posedge av_clk or posedge av_rst)
        if (av_rst)
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

    always @ (posedge av_clk)
        if (sync_av == 2'b01)
            {av_live, av_running, av_done, av_mode, av_force, av_arm} <=
                            {lsa_live, lsa_running, lsa_done, ctrl_mode, ctrl_force, ctrl_arm};

    always @ (posedge lsa_clk)
        if (sync_lsa == 2'b10)
            {lsa_live, lsa_running, lsa_done, lsa_mode, lsa_force, lsa_arm} <=
                            {sample_live, sample_running, sample_done, av_mode, av_force, av_arm};

    //
    // Sample state machine
    //

    reg [10:0] sample_waddr;
    assign sample_running = sample_waddr[10];
    reg [31:0] sample_data[1023:0];

    always @ (posedge lsa_clk)
        sample_done <= lsa_arm && (sample_waddr == 11'h000);

    always @ (posedge lsa_clk)
        if (!lsa_arm)
            sample_waddr <= 11'h001;
        else if (!sample_waddr[10] && |sample_waddr[9:0])
            sample_waddr <= sample_waddr + 11'd1;
        else if (sample_waddr == 11'h400)
            sample_waddr <= (lsa_force || lsa_trigger) ? 11'h401 : 11'h400;
        else if (sample_waddr != 11'h000)
            sample_waddr <= sample_waddr + 10'd1;

    always @ (posedge lsa_clk)
        if (lsa_arm)
            sample_data[sample_waddr[9:0]] <= (sample_waddr[10]) ? lsa_data : 32'd0;

    //
    // Control register
    //

    reg init_cycle;

    always @ (posedge av_clk or posedge av_rst)
        if (av_rst)
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
        else if (av_write && (av_address == 10'd0))
        begin
            ctrl_arm <= av_writedata[0];
            ctrl_force <= av_writedata[1];
            ctrl_mode <= av_writedata[15:8];
        end

    always @ (posedge av_clk)
        av_readdatavalid <= av_read;

    always @ (posedge av_clk)
        if (av_address == 10'd0)
            av_readdata <= {16'd0, ctrl_mode, 4'd0, av_running, av_done, ctrl_force, ctrl_arm};
        else if (av_address == 10'd1)
            av_readdata <= av_live;
        else
            av_readdata <= sample_data[av_address];

endmodule
