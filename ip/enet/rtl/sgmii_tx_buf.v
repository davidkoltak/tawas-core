/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * Buffer GMII cycles and convert to TBI - send SGMII autoneg cycles
 */

module sgmii_tx_buf
(
    input clk_125mhz,
    input rst,

    input tbi_tx_rdy,
    input tbi_tx_clk,

    input sgmii_autoneg_start,
    input sgmii_autoneg_ack,
    input sgmii_autoneg_done,
    
    input [7:0] gmii_txd,
    input gmii_tx_en,
    input gmii_tx_err,
    
    output [7:0] tx_byte,
    output tx_is_k
);
    parameter CONFIG_REG = 16'h01A0;
    
    //
    // TX buffer write
    //
    
    wire [8:0] fifo_in = {gmii_tx_err, gmii_txd};
    wire fifo_push = gmii_tx_en && sgmii_autoneg_done;
    wire [8:0] fifo_out;
    reg fifo_pop;
    wire fifo_empty;
    
    sgmii_fifo sgmii_fifo
    (
        .rst_in(rst),
        .clk_in(clk_125mhz),
        .clk_out(tbi_tx_clk),

        .fifo_in(fifo_in),
        .push(fifo_push),
        .full(),

        .fifo_out(fifo_out),
        .pop(fifo_pop),
        .empty(fifo_empty)
    );

    //
    // Fifo hystoresis
    //
    
    reg [2:0] cycle_cnt;
    
    always @ (posedge tbi_tx_clk)
        fifo_pop <= &cycle_cnt[2];
    
    always @ (posedge clk_125mhz or posedge rst)
        if (rst)
            cycle_cnt <= 3'd0;
        else if (fifo_empty)
            cycle_cnt <= 3'd0;
        else if (fifo_push && !fifo_pop)
            cycle_cnt <= cycle_cnt + 3'd1;

    //
    // Autogen sequence
    //
    
    reg [2:0] autoneg_state;
    reg [11:0] autoneg_cnt;
    wire autoneg_cnt_done = (autoneg_cnt == 12'd1000);
    wire [15:0] autoneg_reg = (!autoneg_cnt_done) ? 16'd0 :
                              (!sgmii_autoneg_ack) ? (CONFIG_REG | 16'h0001)
                                                   : (CONFIG_REG | 16'h4001);
    reg [8:0] autoneg_out;
    
    always @ (posedge tbi_tx_clk or negedge tbi_tx_rdy)
        if (!tbi_tx_rdy)
            autoneg_state <= 3'd0;
        else
            autoneg_state <= autoneg_state + 3'd1;
    
    always @ (posedge tbi_tx_clk or negedge tbi_tx_rdy)
        if (!tbi_tx_rdy)
            autoneg_cnt <= 12'd0;
        else if (!sgmii_autoneg_start)
            autoneg_cnt <= 12'd0;
        else if (!autoneg_cnt_done)
            autoneg_cnt <= autoneg_cnt + 12'd1;

    always @ (posedge tbi_tx_clk)
        case (autoneg_state)
        3'd1: autoneg_out <= {1'b1, 8'hBC};
        3'd2: autoneg_out <= {1'b0, autoneg_reg[7:0]};
        3'd3: autoneg_out <= {1'b0, autoneg_reg[15:8]};
        3'd5: autoneg_out <= {1'b1, 8'h42};
        3'd6: autoneg_out <= {1'b0, autoneg_reg[7:0]};
        3'd7: autoneg_out <= {1'b0, autoneg_reg[15:8]};
        default: autoneg_out <= {1'b1, 8'hBC};
        endcase

    //
    // Encapsulation
    //
    
    reg [3:0] encap_state;
    reg [8:0] encap_out;
    
    always @ (posedge tbi_tx_clk or negedge tbi_tx_rdy)
        if (!tbi_tx_rdy)
            encap_state <= 4'd0;
        else
            case (encap_state)
            4'd3: encap_state <= 4'd0;
            default: encap_state <= encap_state + 4'd1;
            endcase
            
    always @ (posedge tbi_tx_clk or negedge tbi_tx_rdy)
        if (!tbi_tx_rdy)
            encap_out <= 9'd0;
        else
            case (encap_state)
            4'd0: encap_out <= {1'b1, 8'hBC};
            4'd1: encap_out <= {1'b0, 8'hC5};
            4'd2: encap_out <= {1'b1, 8'hBC};
            4'd3: encap_out <= {1'b0, 8'hC5};
            default: encap_out <= 9'd0;
            endcase

    //
    // TBI out
    //
    
    assign tx_byte = (sgmii_autoneg_done) ? encap_out[7:0] : autoneg_out[7:0];
    assign tx_is_k = (sgmii_autoneg_done) ? encap_out[8] : autoneg_out[8];
    
endmodule
