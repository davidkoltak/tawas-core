/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * Simple testcase for SGMII TBI logic
 */
 
module testbench();

    reg rst;
    reg clk_125mhz;
    reg clk_125mhz_gen;
    integer cycle_count;

    initial
    begin
        rst = 1;
        clk_125mhz_gen = 0;
        $dumpfile("results.vcd");
        $dumpvars(0);
        cycle_count = 0;
        #125 rst = 0;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #23 rst = 1;
        #23 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen;
        #125 clk_125mhz_gen = ~clk_125mhz_gen; rst = 0;
        while (1)
        begin
            #125 clk_125mhz_gen = ~clk_125mhz_gen;
            cycle_count = (clk_125mhz_gen) ? cycle_count : cycle_count + 1;
        end
    end

    always @ (clk_125mhz_gen)
        clk_125mhz <= clk_125mhz_gen;

    reg
    
    //
    // Slightly faster clock
    //
    
    reg clk_126mhz;
    reg clk_126mhz_gen;
    
    initial
    begin
        clk_126mhz_gen = 0;
        while (1)
            #124 clk_126mhz_gen = ~clk_126mhz_gen;
    end
    
    always @ (clk_126mhz_gen)
        clk_126mhz <= clk_126mhz_gen;
    
    //
    // Slightly slower clock
    //
    
    reg clk_124mhz;
    reg clk_124mhz_gen;
    
    initial
    begin
        clk_124mhz_gen = 0;
        while (1)
            #124 clk_124mhz_gen = ~clk_124mhz_gen;
    end
    
    always @ (clk_124mhz_gen)
        clk_124mhz <= clk_124mhz_gen;
    
    //
    // Test state machine
    //
    
    integer tstate;
    reg tbi_rx_rdy;
    reg tbi_tx_rdy;
    reg [7:0] gmii_txd_main;
    reg gmii_tx_en_main;
    reg gmii_tx_err_main;
    wire [7:0] gmii_rxd_main;
    wire gmii_rx_dv_main;
    wire gmii_rx_err_main;
    wire autoneg_complete_main;
    wire [15:0] config_reg_main;
    wire autoneg_complete_loop;
    wire [15:0] config_reg_loop;

    always @ (posedge clk_125mhz or posedge rst)
        if (rst)
            tstate <= 0;
        else
            case (tstate)
            20: if (autoneg_complete_main) tstate <= tstate + 1;
            25: if (autoneg_complete_loop) tstate <= tstate + 1;
            default: tstate <= tstate + 1;
            endcase
            
    always @ (posedge clk_125mhz or posedge rst)
        if (rst)
        begin
            tbi_rx_rdy <= 1'b0;
            tbi_tx_rdy <= 1'b0;
            gmii_txd_main <= 8'd0;
            gmii_tx_en_main <= 1'b0;
            gmii_tx_err_main <= 1'b0;
        end
        else
            case (tstate)
            
            10: tbi_rx_rdy <= 1'b1;
            15: tbi_tx_rdy <= 1'b1;
            
            40:
            begin
                gmii_txd_main <= 8'h77;
                gmii_tx_en_main <= 1'b1;
            end
            41: gmii_txd_main <= 8'h88;
            42: gmii_txd_main <= 8'h99;
            43: gmii_txd_main <= 8'h50;
            44: gmii_txd_main <= 8'h51;
            45: gmii_txd_main <= 8'h52;
            46: gmii_tx_en_main <= 1'b0;


            60:
            begin
                gmii_txd_main <= 8'h99;
                gmii_tx_en_main <= 1'b1;
            end
            61: gmii_txd_main <= 8'h88;
            62: gmii_txd_main <= 8'h77;
            63: gmii_txd_main <= 8'h20;
            64:
            begin
                gmii_txd_main <= 8'h21;
                gmii_tx_err_main <= 1'b1;
            end
            65:
            begin
                gmii_txd_main <= 8'h22;
                gmii_tx_err_main <= 1'b0;
            end
            66: gmii_tx_en_main <= 1'b0;
            
            100:
            begin
                gmii_txd_main <= 8'd0;
                gmii_tx_en_main <= 1'b1;
            end
            101: gmii_txd_main <= 8'd1;
            102: gmii_txd_main <= 8'd2;
            103: gmii_txd_main <= 8'd3;
            104: gmii_txd_main <= 8'd4;
            105: gmii_txd_main <= 8'd5;
            106: gmii_txd_main <= 8'd6;
            107: gmii_txd_main <= 8'd7;
            108: gmii_txd_main <= 8'd8;
            109: gmii_txd_main <= 8'd9;
            110: gmii_txd_main <= 8'd10;
            111: gmii_txd_main <= 8'd11;
            112: gmii_txd_main <= 8'd12;
            113: gmii_txd_main <= 8'd13;
            114: gmii_txd_main <= 8'd14;
            115: gmii_txd_main <= 8'd15;
            116: gmii_txd_main <= 8'd16;
            117: gmii_txd_main <= 8'd17;
            118: gmii_txd_main <= 8'd18;
            119: gmii_txd_main <= 8'd19;
            120: gmii_txd_main <= 8'd20;
            121: gmii_txd_main <= 8'd21;
            122: gmii_txd_main <= 8'd22;
            123: gmii_txd_main <= 8'd23;
            124: gmii_txd_main <= 8'd24;
            125: gmii_txd_main <= 8'd25;
            126: gmii_txd_main <= 8'd26;
            127: gmii_txd_main <= 8'd27;
            128: gmii_txd_main <= 8'd28;
            129: gmii_txd_main <= 8'd29;
            130: gmii_txd_main <= 8'd30;
            131: gmii_txd_main <= 8'd31;
            132: gmii_txd_main <= 8'd32;
            133: gmii_txd_main <= 8'd33;
            134: gmii_txd_main <= 8'd34;
            135: gmii_txd_main <= 8'd35;
            136: gmii_txd_main <= 8'd36;
            137: gmii_txd_main <= 8'd37;
            138: gmii_txd_main <= 8'd38;
            139: gmii_txd_main <= 8'd39;
            140: gmii_tx_en_main <= 1'b0;
            
            10000: $finish();
            default: ;
            endcase

    //
    // DUT instance - loopback one to the other
    //
    
    wire [7:0] gmii_txd_loop;
    wire gmii_tx_en_loop;
    wire gmii_tx_err_loop;
    
    wire [9:0] tbi_rxd;
    wire [9:0] tbi_txd;
    
    sgmii_tbi sgmii_tbi_main
    (
        .clk_125mhz(clk_125mhz),
        .rst(rst),
        
        .autoneg_complete(autoneg_complete_main),
        .config_reg(config_reg_main),
        
        .gmii_rxd(gmii_rxd_main),
        .gmii_rx_dv(gmii_rx_dv_main),
        .gmii_rx_err(gmii_rx_err_main),
        
        .gmii_txd(gmii_txd_main),
        .gmii_tx_en(gmii_tx_en_main),
        .gmii_tx_err(gmii_tx_err_main),
        
        .tbi_rx_rdy(tbi_rx_rdy),
        .tbi_rx_clk(clk_124mhz),
        .tbi_rxd(tbi_rxd),
        
        .tbi_tx_rdy(tbi_tx_rdy),
        .tbi_tx_clk(clk_126mhz),
        .tbi_txd(tbi_txd)
    );

    
    sgmii_tbi sgmii_tbi_loopback
    (
        .clk_125mhz(clk_125mhz),
        .rst(rst),
        
        .autoneg_complete(autoneg_complete_loop),
        .config_reg(config_reg_loop),
        
        .gmii_rxd(gmii_txd_loop),
        .gmii_rx_dv(gmii_tx_en_loop),
        .gmii_rx_err(gmii_tx_err_loop),
        
        .gmii_txd(gmii_txd_loop),
        .gmii_tx_en(gmii_tx_en_loop),
        .gmii_tx_err(gmii_tx_err_loop),
        
        .tbi_rx_rdy(tbi_rx_rdy),
        .tbi_rx_clk(clk_126mhz),
        .tbi_rxd(tbi_txd),
        
        .tbi_tx_rdy(tbi_tx_rdy),
        .tbi_tx_clk(clk_124mhz),
        .tbi_txd(tbi_rxd)
    );
    
endmodule
