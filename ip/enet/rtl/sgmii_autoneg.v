/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
 * SGMII autonegotiation state machine
 */
 
module sgmii_autoneg
(
    input tbi_rx_rdy,
    input tbi_rx_clk,

    input [7:0] rx_byte,
    input rx_is_k,
    input rx_disp_err,

    output sgmii_autoneg_start,
    output sgmii_autoneg_ack,
    output sgmii_autoneg_done,
    output [15:0] sgmii_config
);

    //
    // RX Autonegotiation state machine
    //

    reg [5:0] rx_state;
    wire [5:0] rx_state_next = (rx_state + 6'd1);
    reg rx_state_start;
    reg rx_state_ack;
    reg rx_state_complete;
    reg [11:0] rx_cfg_cnt;
    reg [15:0] rx_cfg1;
    reg [15:0] rx_cfg2;
    reg [15:0] rx_cfg;
    
    wire rx_error = rx_disp_err || (rx_is_k && (rx_byte == 8'd0));
    
    assign sgmii_autoneg_start = rx_state_start;
    assign sgmii_autoneg_ack <= rx_state_ack;
    assign sgmii_autoneg_done = rx_state_complete;
    assign sgmii_config = rx_cfg;
    
    always @ (posedge tbi_rx_clk or negedge tbi_rx_rdy)
        if (!tbi_rx_rdy)
        begin
            rx_state <= 6'd0;
            rx_state_start <= 1'b0;
            rx_state_ack <= 1'b0;
            rx_state_complete <= 1'b0;
            rx_cfg_cnt <= 12'd0;
            rx_cfg1 <= 16'd0;
            rx_cfg2 <= 16'd0;
            rx_cfg <= 16'd0;
        end
        else
            case (rx_state)
            6'd0:
            begin
                rx_state <= 6'd1;
                rx_state_start <= 1'b0;
                rx_state_ack <= 1'b0;
                rx_state_complete <= 1'b0;
                rx_cfg_cnt <= 12'd0;
                rx_cfg1 <= 16'd0;
                rx_cfg2 <= 16'd0;
                rx_cfg <= 16'd0;
            end

            // Search for first CFG1/2
            6'd1: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd1;
            6'd2: rx_state <= (rx_is_k && (rx_byte == 8'hB5)) ? rx_state_next : 6'd1;
            6'd3: rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            6'd4: rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            6'd5: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd0;
            6'd6: rx_state <= (rx_is_k && (rx_byte == 8'h42)) ? rx_state_next : 6'd0;
            6'd7: rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            6'd8: rx_state <= (rx_is_k) ? 6'd0 : 6'd11;
            
            // Continue to count 1000 x CFG1/2
            6'd11: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd0;
            6'd12: rx_state <= (rx_is_k && (rx_byte == 8'hB5)) ? rx_state_next : 6'd0;
            6'd13:
            begin
                rx_state_start <= 1'b1;
                rx_cfg_cnt <= rx_cfg_cnt + 12'd1;
                rx_cfg1[7:0] <= rx_byte;
                rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            end
            6'd14:
            begin
                rx_cfg1[15:8] <= rx_byte;
                rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            end
            6'd15: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd0;
            6'd16: rx_state <= (rx_is_k && (rx_byte == 8'h42)) ? rx_state_next : 6'd0;
            6'd17:
            begin
                rx_cfg2[7:0] <= rx_byte;
                rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            end
            6'd18:
            begin
                rx_cfg2[15:8] <= rx_byte;
                rx_state <= (rx_is_k) ? 6'd0 : 
                            (rx_cfg_cnt == 12'd1000) ? 6'd21 : 6'd11;
            end
            
            // Wait for non-zero CFG, check CFG1 == CFG2 from now on
            6'd21: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd0;
            6'd22: rx_state <= (rx_is_k && (rx_byte == 8'hB5)) ? rx_state_next : 6'd0;
            6'd23:
            begin
                rx_cfg1[7:0] <= rx_byte;
                rx_state <= (rx_is_k || (rx_cfg1 != rx_cfg2)) ? 6'd0 : rx_state_next;
            end
            6'd24:
            begin
                rx_cfg1[15:8] <= rx_byte;
                rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            end
            6'd25: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd0;
            6'd26: rx_state <= (rx_is_k && (rx_byte == 8'h42)) ? rx_state_next : 6'd0;
            6'd27:
            begin
                rx_cfg2[7:0] <= rx_byte;
                rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            end
            6'd28:
            begin
                rx_cfg2[15:8] <= rx_byte;
                rx_cfg <= rx_cfg1;
                rx_state <= (rx_is_k) ? 6'd0 : 
                            (rx_cfg1[0]) ? 6'd31 : 6'd21;
            end
 
             // Wait for ACK, check CFG1 == CFG2 from now on
            6'd31: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd0;
            6'd32: rx_state <= (rx_is_k && (rx_byte == 8'hB5)) ? rx_state_next : 6'd0;
            6'd33:
            begin
                rx_state_ack <= 1'b1;
                rx_cfg1[7:0] <= rx_byte;
                rx_state <= (rx_is_k || (rx_cfg1 != rx_cfg2)) ? 6'd0 : rx_state_next;
            end
            6'd34:
            begin
                rx_cfg1[15:8] <= rx_byte;
                rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            end
            6'd35: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd0;
            6'd36: rx_state <= (rx_is_k && (rx_byte == 8'h42)) ? rx_state_next : 6'd0;
            6'd37:
            begin
                rx_cfg2[7:0] <= rx_byte;
                rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            end
            6'd38:
            begin
                rx_cfg2[15:8] <= rx_byte;
                rx_cfg <= rx_cfg1;
                rx_state <= (rx_is_k) ? 6'd0 : 
                            (rx_cfg1[14] && rx_cfg1[0]) ? 6'd41 : (!rx_cfg1[0]) ? 6'd0 : 6'd31;
            end
            
            // Continue to count 3 more x CFG1/2, must match previous non-zero value
            6'd41: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd0;
            6'd42: rx_state <= (rx_is_k && (rx_byte == 8'hB5)) ? rx_state_next : 6'd0;
            6'd43:
            begin
                rx_cfg_cnt <= rx_cfg_cnt + 12'd1;
                rx_cfg1[7:0] <= rx_byte;
                rx_state <= (rx_is_k || (rx_cfg1 != rx_cfg2) || (rx_cfg1 != rx_cfg)) ? 6'd0 : rx_state_next;
            end
            6'd44:
            begin
                rx_cfg1[15:8] <= rx_byte;
                rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            end
            6'd45: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd0;
            6'd46: rx_state <= (rx_is_k && (rx_byte == 8'h42)) ? rx_state_next : 6'd0;
            6'd47:
            begin
                rx_cfg2[7:0] <= rx_byte;
                rx_state <= (rx_is_k) ? 6'd0 : rx_state_next;
            end
            6'd48:
            begin
                rx_cfg2[15:8] <= rx_byte;
                rx_state <= (rx_is_k) ? 6'd0 : 
                            (rx_cfg_cnt == 12'd1003) ? 6'd51 : 6'd11;
            end
            
            // Wait for 2 x IDLE1/2
            6'd51: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd41;
            6'd52: rx_state <= (rx_is_k && (rx_byte == 8'hC5)) ? rx_state_next : 6'd41;
            6'd53: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd41;
            6'd54: rx_state <= (rx_is_k && (rx_byte == 8'h50)) ? rx_state_next : 6'd41;
            6'd55: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd41;
            6'd56: rx_state <= (rx_is_k && (rx_byte == 8'hC5)) ? rx_state_next : 6'd41;
            6'd57: rx_state <= (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : 6'd41;
            6'd58: rx_state <= (rx_is_k && (rx_byte == 8'h50)) ? 6'd51 : 6'd41;
            
            // Done receiving CFG - restart on error or seeing another CFG sequence
            6'd61:
            begin
                rx_state_complete <= 1'b1;
                rx_state <= rx_state_next;
            end
            6'd62:
                rx_state <= (rx_error) ? 6'd0 : 
                            (rx_is_k && (rx_byte == 8'hBC)) ? rx_state_next : rx_state;
            6'd63:
                rx_state <= (rx_error) ? 6'd0 : 
                            (rx_is_k && ((rx_byte == 8'hB5) || (rx_byte == 8'h42)) ? 6'd0 : 6'd42;
            
            default: rx_state <= 6'd0;
            endcase
            
endmodule
