/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * Buffer GMII cycles and convert to TBI - send SGMII autoneg cycles
 */

module sgmii_tx_buf
(
    input clk_125mhz,
    input rst,

    input tbi_tx_clk,

    input sgmii_autoneg_start,
    input sgmii_autoneg_ack,
    input sgmii_autoneg_idle,
    input sgmii_autoneg_done,
    
    input [7:0] gmii_txd,
    input gmii_tx_en,
    input gmii_tx_err,
    
    output [7:0] tx_byte,
    output tx_is_k
);
    parameter CONFIG_REG = 16'h0180; // Full Duplex, 1Gbps
    //parameter CONFIG_REG = 16'h0140; // Full Duplex, 100Mbps
    //parameter CONFIG_REG = 16'h0100; // Full Duplex, 10Mbps
    
    //
    // TX buffer write
    //
    
    wire [8:0] fifo_in = {gmii_tx_err, gmii_txd};
    wire fifo_push = gmii_tx_en && sgmii_autoneg_done;
    wire [8:0] fifo_out;
    wire fifo_pop;
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
    // Autogen sequence
    //
    
    wire [15:0] autoneg_config = CONFIG_REG;
    reg [4:0] autoneg_state;
    wire [4:0] autoneg_state_next = autoneg_state + 5'd1;
    reg [11:0] autoneg_cnt;
    reg [8:0] autoneg_out;
    reg autoneg_done;
    
    always @ (posedge tbi_tx_clk or posedge rst)
        if (rst)
        begin
            autoneg_state <= 5'd0;
            autoneg_cnt <= 12'd0;
            autoneg_out <= 9'd0;
            autoneg_done <= 1'b0;
        end
        else
            case (autoneg_state)
            // 1000 x CFG1/2 of zero
            5'd0:
            begin
                autoneg_done <= 1'b0;
                if (!sgmii_autoneg_start) autoneg_cnt <= 12'd0;
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b1, 8'hBC};
            end
            5'd1:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, 8'hB5};
            end
            5'd2:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, 8'h00};
            end
            5'd3:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, 8'h00};
            end
            5'd4:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b1, 8'hBC};
            end
            5'd5:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, 8'h42};
            end
            5'd6:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, 8'h00};
                autoneg_cnt <= autoneg_cnt + 12'd1;
            end
            5'd7:
            begin
                autoneg_state <= (autoneg_cnt == 12'd1000) ? autoneg_state_next : 5'd0;
                autoneg_out <= {1'b0, 8'h00};
            end

            // Send non-ACK with CONFIG_REG
            5'd8:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b1, 8'hBC};
            end
            5'd9:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, 8'hB5};
            end
            5'd10:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, autoneg_config[7:0] | 8'h01};
            end
            5'd11:
            begin
                autoneg_state <= (!sgmii_autoneg_start) ? 5'd0 : autoneg_state_next;
                autoneg_out <= {1'b0, autoneg_config[15:8]};
            end
            5'd12:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b1, 8'hBC};
            end
            5'd13:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, 8'h42};
            end
            5'd14:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, autoneg_config[7:0] | 8'h01};
                autoneg_cnt <= autoneg_cnt + 12'd1;
            end
            5'd15:
            begin
                autoneg_state <= (sgmii_autoneg_ack) ? autoneg_state_next : 5'd8;
                autoneg_out <= {1'b0, autoneg_config[15:8]};
            end
  
            // Send ACK with CONFIG_REG
            5'd16:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b1, 8'hBC};
            end
            5'd17:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, 8'hB5};
            end
            5'd18:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, autoneg_config[7:0] | 8'h01};
            end
            5'd19:
            begin
                autoneg_state <= (!sgmii_autoneg_start) ? 5'd0 : autoneg_state_next;
                autoneg_out <= {1'b0, autoneg_config[15:8] | 8'h40};
            end
            5'd20:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b1, 8'hBC};
            end
            5'd21:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, 8'h42};
            end
            5'd22:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, autoneg_config[7:0] | 8'h01};
                autoneg_cnt <= autoneg_cnt + 12'd1;
            end
            5'd23:
            begin
                autoneg_state <= (sgmii_autoneg_idle) ? autoneg_state_next : 5'd16;
                autoneg_out <= {1'b0, autoneg_config[15:8] | 8'h40};
            end
 
             // Send IDLE
            5'd24:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b1, 8'hBC};
            end
            5'd25:
            begin
                autoneg_state <= (!sgmii_autoneg_start) ? 5'd0 : autoneg_state_next;
                autoneg_out <= {1'b0, 8'hC5};
            end
            5'd26:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b1, 8'hBC};
            end
            5'd27:
            begin
                autoneg_state <= autoneg_state_next;
                autoneg_out <= {1'b0, 8'h50};
            end
            5'd28:
            begin
                autoneg_done <= 1'b1;
                if (!sgmii_autoneg_start || !sgmii_autoneg_ack || !sgmii_autoneg_ack)
                    autoneg_state <= 5'd0;
            end
            
            default: autoneg_state <= 5'd0;
            endcase


    //
    // Encapsulation
    //
    
    reg [2:0] encap_state;
    reg [8:0] encap_out;
    assign fifo_pop = (encap_state == 3'd5);
    
    always @ (posedge tbi_tx_clk or posedge rst)
        if (rst)
            encap_state <= 3'd0;
        else if (autoneg_state == 5'd27)
            encap_state <= 3'd0;
        else
            case (encap_state)
            3'd3: encap_state <= (!fifo_empty) ? 3'd4 : 3'd0;
            3'd5: encap_state <= (fifo_empty) ? 3'd6 : 3'd5;
            3'd6: encap_state <= 3'd0;
            default: encap_state <= encap_state + 3'd1;
            endcase
            
    always @ (posedge tbi_tx_clk or posedge rst)
        if (rst)
            encap_out <= 9'd0;
        else
            case (encap_state)
            3'd0: encap_out <= {1'b1, 8'hBC};
            3'd1: encap_out <= {1'b0, 8'hC5};
            3'd2: encap_out <= {1'b1, 8'hBC};
            3'd3: encap_out <= {1'b0, 8'h50};
            
            3'd4: encap_out <= {1'b1, 8'hFB};
            3'd5: encap_out <= (fifo_empty) ? {1'b1, 8'hFD} : 
                               (fifo_out[8]) ? {1'b1, 8'hFE} : {1'b0, fifo_out[7:0]};
            3'd6: encap_out <= {1'b1, 8'hF7};
            default: encap_out <= 9'd0;
            endcase

    //
    // TBI out
    //
    
    assign tx_byte = (autoneg_done) ? encap_out[7:0] : autoneg_out[7:0];
    assign tx_is_k = (autoneg_done) ? encap_out[8] : autoneg_out[8];
    
endmodule
