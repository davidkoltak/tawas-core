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
    
    always @ (posedge clk_125mhz or posedge rst)
        if (rst)
        begin
            tstate <= 0;
        end
        else
            case (tstate)
            
            1000: $finish();
            default: tstate <= tstate + 1;
            endcase

    //
    // DUT instance - loopback one to the other
    //
    
    wire autoneg_complete_main;
    wire [15:0] config_reg_main;
    
    wire autoneg_complete_loop;
    wire [15:0] config_reg_loop;
    
    wire [7:0] gmii_rxd_main;
    wire gmii_rx_dv_main;
    wire gmii_rx_err_main;
    
    wire [7:0] gmii_txd_main;
    wire gmii_tx_en_main;
    wire gmii_tx_err_main;
    
    wire [7:0] gmii_txd_loop;
    wire gmii_tx_en_loop;
    wire gmii_tx_err_loop;
    
    wire tbi_rx_rdy;
    wire tbi_rx_clk;
    wire [9:0] tbi_rxd;
    
    wire tbi_tx_rdy;
    wire tbi_tx_clk;
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
        
        .gmii_rxd(gmii_rxd_loop),
        .gmii_rx_dv(gmii_rx_dv_loop),
        .gmii_rx_err(gmii_rx_err_loop),
        
        .gmii_txd(gmii_rxd_loop),
        .gmii_tx_en(gmii_rx_dv_loop),
        .gmii_tx_err(gmii_rx_err_loop),
        
        .tbi_rx_rdy(tbi_rx_rdy),
        .tbi_rx_clk(clk_124mhz),
        .tbi_rxd(tbi_txd),
        
        .tbi_tx_rdy(tbi_tx_rdy),
        .tbi_tx_clk(clk_124mhz),
        .tbi_txd(tbi_rxd)
    );
    
endmodule
