/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

/*
        /C/     - Configuration         - Alternating /C1/ and /C2/
        --------------------------------------------------------------------
        /C1/    - Configuration 1       - /K28.5(BC)/D21.5(B5)/Config_Rega
        /C2/    - Configuration 2       - /K28.5(BC)/D2.2(42)/Config_Rega
        
        /I/     - IDLE                  - Correcting /I1/, Preserving /I2/
        --------------------------------------------------------------------
        /I1/    - IDLE 1                - /K28.5(BC)/D5.6(C5)/
        /I2/    - IDLE 2                - /K28.5(BC)/D16.2(50)/
        
                - Encapsulation
        --------------------------------------------------------------------
        /R/     - Carrier_Extend        - /K23.7(F7)/
        /S/     - Start_of_Packet       - /K27.7(FB)/
        /T/     - End_of_Packet         - /K29.7(FD)/
        /V/     - Error_Propagation     - /K30.7(FE)/
*/

module sgmii_8b10b_encode
(
    input clk,
    input rst,
    
    input [7:0] eight_bit,
    input is_k,
    
    output [9:0] ten_bit
);

    reg [9:0] ov;
    reg [9:0] dx_crd_neg;
    reg [9:0] dx_crd_pos;
    reg [9:0] kx_crd_neg;
    reg [9:0] kx_crd_pos;
    
    reg [3:0] current_rd;
    wire [3:0] bit_cnt;
    
    assign bit_cnt = {3'd0, ov[9]} + {3'd0, ov[8]} + {3'd0, ov[7]} + 
                     {3'd0, ov[6]} + {3'd0, ov[5]} + {3'd0, ov[4]} + 
                     {3'd0, ov[3]} + {3'd0, ov[2]} + {3'd0, ov[1]} + 
                     {3'd0, ov[0]};
        
    always @ (posedge clk or posedge rst)
        if (rst)
            current_rd <= 4'd0;
        else
            current_rd <= current_rd + (bit_cnt - 4'd5);

    always @ (posedge clk)
        case ({is_k, current_rd[3]})
        2'b01: ov <= dx_crd_neg;
        2'b00: ov <= dx_crd_pos;
        2'b11: ov <= kx_crd_neg;
        default: ov <= kx_crd_pos;
        endcase

    assign ten_bit = ov;
    
    always @ (posedge clk)
        case (eight_bit)
        8'h00: dx_crd_neg <= 10'b1001110100;
        8'h01: dx_crd_neg <= 10'b0111010100;
        8'h02: dx_crd_neg <= 10'b1011010100;
        8'h03: dx_crd_neg <= 10'b1100011011;
        8'h04: dx_crd_neg <= 10'b1101010100;
        8'h05: dx_crd_neg <= 10'b1010011011;
        8'h06: dx_crd_neg <= 10'b0110011011;
        8'h07: dx_crd_neg <= 10'b1110001011;
        8'h08: dx_crd_neg <= 10'b1110010100;
        8'h09: dx_crd_neg <= 10'b1001011011;
        8'h0A: dx_crd_neg <= 10'b0101011011;
        8'h0B: dx_crd_neg <= 10'b1101001011;
        8'h0C: dx_crd_neg <= 10'b0011011011;
        8'h0D: dx_crd_neg <= 10'b1011001011;
        8'h0E: dx_crd_neg <= 10'b0111001011;
        8'h0F: dx_crd_neg <= 10'b0101110100;
        8'h10: dx_crd_neg <= 10'b0110110100;
        8'h11: dx_crd_neg <= 10'b1000111011;
        8'h12: dx_crd_neg <= 10'b0100111011;
        8'h13: dx_crd_neg <= 10'b1100101011;
        8'h14: dx_crd_neg <= 10'b0010111011;
        8'h15: dx_crd_neg <= 10'b1010101011;
        8'h16: dx_crd_neg <= 10'b0110101011;
        8'h17: dx_crd_neg <= 10'b1110100100;
        8'h18: dx_crd_neg <= 10'b1100110100;
        8'h19: dx_crd_neg <= 10'b1001101011;
        8'h1A: dx_crd_neg <= 10'b0101101011;
        8'h1B: dx_crd_neg <= 10'b1101100100;
        8'h1C: dx_crd_neg <= 10'b0011101011;
        8'h1D: dx_crd_neg <= 10'b1011100100;
        8'h1E: dx_crd_neg <= 10'b0111100100;
        8'h1F: dx_crd_neg <= 10'b1010110100;
        8'h20: dx_crd_neg <= 10'b1001111001;
        8'h21: dx_crd_neg <= 10'b0111011001;
        8'h22: dx_crd_neg <= 10'b1011011001;
        8'h23: dx_crd_neg <= 10'b1100011001;
        8'h24: dx_crd_neg <= 10'b1101011001;
        8'h25: dx_crd_neg <= 10'b1010011001;
        8'h26: dx_crd_neg <= 10'b0110011001;
        8'h27: dx_crd_neg <= 10'b1110001001;
        8'h28: dx_crd_neg <= 10'b1110011001;
        8'h29: dx_crd_neg <= 10'b1001011001;
        8'h2A: dx_crd_neg <= 10'b0101011001;
        8'h2B: dx_crd_neg <= 10'b1101001001;
        8'h2C: dx_crd_neg <= 10'b0011011001;
        8'h2D: dx_crd_neg <= 10'b1011001001;
        8'h2E: dx_crd_neg <= 10'b0111001001;
        8'h2F: dx_crd_neg <= 10'b0101111001;
        8'h30: dx_crd_neg <= 10'b0110111001;
        8'h31: dx_crd_neg <= 10'b1000111001;
        8'h32: dx_crd_neg <= 10'b0100111001;
        8'h33: dx_crd_neg <= 10'b1100101001;
        8'h34: dx_crd_neg <= 10'b0010111001;
        8'h35: dx_crd_neg <= 10'b1010101001;
        8'h36: dx_crd_neg <= 10'b0110101001;
        8'h37: dx_crd_neg <= 10'b1110101001;
        8'h38: dx_crd_neg <= 10'b1100111001;
        8'h39: dx_crd_neg <= 10'b1001101001;
        8'h3A: dx_crd_neg <= 10'b0101101001;
        8'h3B: dx_crd_neg <= 10'b1101101001;
        8'h3C: dx_crd_neg <= 10'b0011101001;
        8'h3D: dx_crd_neg <= 10'b1011101001;
        8'h3E: dx_crd_neg <= 10'b0111101001;
        8'h3F: dx_crd_neg <= 10'b1010111001;
        8'h40: dx_crd_neg <= 10'b1001110101;
        8'h41: dx_crd_neg <= 10'b0111010101;
        8'h42: dx_crd_neg <= 10'b1011010101;
        8'h43: dx_crd_neg <= 10'b1100010101;
        8'h44: dx_crd_neg <= 10'b1101010101;
        8'h45: dx_crd_neg <= 10'b1010010101;
        8'h46: dx_crd_neg <= 10'b0110010101;
        8'h47: dx_crd_neg <= 10'b1110000101;
        8'h48: dx_crd_neg <= 10'b1110010101;
        8'h49: dx_crd_neg <= 10'b1001010101;
        8'h4A: dx_crd_neg <= 10'b0101010101;
        8'h4B: dx_crd_neg <= 10'b1101000101;
        8'h4C: dx_crd_neg <= 10'b0011010101;
        8'h4D: dx_crd_neg <= 10'b1011000101;
        8'h4E: dx_crd_neg <= 10'b0111000101;
        8'h4F: dx_crd_neg <= 10'b0101110101;
        8'h50: dx_crd_neg <= 10'b0110110101;
        8'h51: dx_crd_neg <= 10'b1000110101;
        8'h52: dx_crd_neg <= 10'b0100110101;
        8'h53: dx_crd_neg <= 10'b1100100101;
        8'h54: dx_crd_neg <= 10'b0010110101;
        8'h55: dx_crd_neg <= 10'b1010100101;
        8'h56: dx_crd_neg <= 10'b0110100101;
        8'h57: dx_crd_neg <= 10'b1110100101;
        8'h58: dx_crd_neg <= 10'b1100110101;
        8'h59: dx_crd_neg <= 10'b1001100101;
        8'h5A: dx_crd_neg <= 10'b0101100101;
        8'h5B: dx_crd_neg <= 10'b1101100101;
        8'h5C: dx_crd_neg <= 10'b0011100101;
        8'h5D: dx_crd_neg <= 10'b1011100101;
        8'h5E: dx_crd_neg <= 10'b0111100101;
        8'h5F: dx_crd_neg <= 10'b1010110101;
        8'h60: dx_crd_neg <= 10'b1001110011;
        8'h61: dx_crd_neg <= 10'b0111010011;
        8'h62: dx_crd_neg <= 10'b1011010011;
        8'h63: dx_crd_neg <= 10'b1100011100;
        8'h64: dx_crd_neg <= 10'b1101010011;
        8'h65: dx_crd_neg <= 10'b1010011100;
        8'h66: dx_crd_neg <= 10'b0110011100;
        8'h67: dx_crd_neg <= 10'b1110001100;
        8'h68: dx_crd_neg <= 10'b1110010011;
        8'h69: dx_crd_neg <= 10'b1001011100;
        8'h6A: dx_crd_neg <= 10'b0101011100;
        8'h6B: dx_crd_neg <= 10'b1101001100;
        8'h6C: dx_crd_neg <= 10'b0011011100;
        8'h6D: dx_crd_neg <= 10'b1011001100;
        8'h6E: dx_crd_neg <= 10'b0111001100;
        8'h6F: dx_crd_neg <= 10'b0101110011;
        8'h70: dx_crd_neg <= 10'b0110110011;
        8'h71: dx_crd_neg <= 10'b1000111100;
        8'h72: dx_crd_neg <= 10'b0100111100;
        8'h73: dx_crd_neg <= 10'b1100101100;
        8'h74: dx_crd_neg <= 10'b0010111100;
        8'h75: dx_crd_neg <= 10'b1010101100;
        8'h76: dx_crd_neg <= 10'b0110101100;
        8'h77: dx_crd_neg <= 10'b1110100011;
        8'h78: dx_crd_neg <= 10'b1100110011;
        8'h79: dx_crd_neg <= 10'b1001101100;
        8'h7A: dx_crd_neg <= 10'b0101101100;
        8'h7B: dx_crd_neg <= 10'b1101100011;
        8'h7C: dx_crd_neg <= 10'b0011101100;
        8'h7D: dx_crd_neg <= 10'b1011100011;
        8'h7E: dx_crd_neg <= 10'b0111100011;
        8'h7F: dx_crd_neg <= 10'b1010110011;
        8'h80: dx_crd_neg <= 10'b1001110010;
        8'h81: dx_crd_neg <= 10'b0111010010;
        8'h82: dx_crd_neg <= 10'b1011010010;
        8'h83: dx_crd_neg <= 10'b1100011101;
        8'h84: dx_crd_neg <= 10'b1101010010;
        8'h85: dx_crd_neg <= 10'b1010011101;
        8'h86: dx_crd_neg <= 10'b0110011101;
        8'h87: dx_crd_neg <= 10'b1110001101;
        8'h88: dx_crd_neg <= 10'b1110010010;
        8'h89: dx_crd_neg <= 10'b1001011101;
        8'h8A: dx_crd_neg <= 10'b0101011101;
        8'h8B: dx_crd_neg <= 10'b1101001101;
        8'h8C: dx_crd_neg <= 10'b0011011101;
        8'h8D: dx_crd_neg <= 10'b1011001101;
        8'h8E: dx_crd_neg <= 10'b0111001101;
        8'h8F: dx_crd_neg <= 10'b0101110010;
        8'h90: dx_crd_neg <= 10'b0110110010;
        8'h91: dx_crd_neg <= 10'b1000111101;
        8'h92: dx_crd_neg <= 10'b0100111101;
        8'h93: dx_crd_neg <= 10'b1100101101;
        8'h94: dx_crd_neg <= 10'b0010111101;
        8'h95: dx_crd_neg <= 10'b1010101101;
        8'h96: dx_crd_neg <= 10'b0110101101;
        8'h97: dx_crd_neg <= 10'b1110100010;
        8'h98: dx_crd_neg <= 10'b1100110010;
        8'h99: dx_crd_neg <= 10'b1001101101;
        8'h9A: dx_crd_neg <= 10'b0101101101;
        8'h9B: dx_crd_neg <= 10'b1101100010;
        8'h9C: dx_crd_neg <= 10'b0011101101;
        8'h9D: dx_crd_neg <= 10'b1011100010;
        8'h9E: dx_crd_neg <= 10'b0111100010;
        8'h9F: dx_crd_neg <= 10'b1010110010;
        8'hA0: dx_crd_neg <= 10'b1001111010;
        8'hA1: dx_crd_neg <= 10'b0111011010;
        8'hA2: dx_crd_neg <= 10'b1011011010;
        8'hA3: dx_crd_neg <= 10'b1100011010;
        8'hA4: dx_crd_neg <= 10'b1101011010;
        8'hA5: dx_crd_neg <= 10'b1010011010;
        8'hA6: dx_crd_neg <= 10'b0110011010;
        8'hA7: dx_crd_neg <= 10'b1110001010;
        8'hA8: dx_crd_neg <= 10'b1110011010;
        8'hA9: dx_crd_neg <= 10'b1001011010;
        8'hAA: dx_crd_neg <= 10'b0101011010;
        8'hAB: dx_crd_neg <= 10'b1101001010;
        8'hAC: dx_crd_neg <= 10'b0011011010;
        8'hAD: dx_crd_neg <= 10'b1011001010;
        8'hAE: dx_crd_neg <= 10'b0111001010;
        8'hAF: dx_crd_neg <= 10'b0101111010;
        8'hB0: dx_crd_neg <= 10'b0110111010;
        8'hB1: dx_crd_neg <= 10'b1000111010;
        8'hB2: dx_crd_neg <= 10'b0100111010;
        8'hB3: dx_crd_neg <= 10'b1100101010;
        8'hB4: dx_crd_neg <= 10'b0010111010;
        8'hB5: dx_crd_neg <= 10'b1010101010;
        8'hB6: dx_crd_neg <= 10'b0110101010;
        8'hB7: dx_crd_neg <= 10'b1110101010;
        8'hB8: dx_crd_neg <= 10'b1100111010;
        8'hB9: dx_crd_neg <= 10'b1001101010;
        8'hBA: dx_crd_neg <= 10'b0101101010;
        8'hBB: dx_crd_neg <= 10'b1101101010;
        8'hBC: dx_crd_neg <= 10'b0011101010;
        8'hBD: dx_crd_neg <= 10'b1011101010;
        8'hBE: dx_crd_neg <= 10'b0111101010;
        8'hBF: dx_crd_neg <= 10'b1010111010;
        8'hC0: dx_crd_neg <= 10'b1001110110;
        8'hC1: dx_crd_neg <= 10'b0111010110;
        8'hC2: dx_crd_neg <= 10'b1011010110;
        8'hC3: dx_crd_neg <= 10'b1100010110;
        8'hC4: dx_crd_neg <= 10'b1101010110;
        8'hC5: dx_crd_neg <= 10'b1010010110;
        8'hC6: dx_crd_neg <= 10'b0110010110;
        8'hC7: dx_crd_neg <= 10'b1110000110;
        8'hC8: dx_crd_neg <= 10'b1110010110;
        8'hC9: dx_crd_neg <= 10'b1001010110;
        8'hCA: dx_crd_neg <= 10'b0101010110;
        8'hCB: dx_crd_neg <= 10'b1101000110;
        8'hCC: dx_crd_neg <= 10'b0011010110;
        8'hCD: dx_crd_neg <= 10'b1011000110;
        8'hCE: dx_crd_neg <= 10'b0111000110;
        8'hCF: dx_crd_neg <= 10'b0101110110;
        8'hD0: dx_crd_neg <= 10'b0110110110;
        8'hD1: dx_crd_neg <= 10'b1000110110;
        8'hD2: dx_crd_neg <= 10'b0100110110;
        8'hD3: dx_crd_neg <= 10'b1100100110;
        8'hD4: dx_crd_neg <= 10'b0010110110;
        8'hD5: dx_crd_neg <= 10'b1010100110;
        8'hD6: dx_crd_neg <= 10'b0110100110;
        8'hD7: dx_crd_neg <= 10'b1110100110;
        8'hD8: dx_crd_neg <= 10'b1100110110;
        8'hD9: dx_crd_neg <= 10'b1001100110;
        8'hDA: dx_crd_neg <= 10'b0101100110;
        8'hDB: dx_crd_neg <= 10'b1101100110;
        8'hDC: dx_crd_neg <= 10'b0011100110;
        8'hDD: dx_crd_neg <= 10'b1011100110;
        8'hDE: dx_crd_neg <= 10'b0111100110;
        8'hDF: dx_crd_neg <= 10'b1010110110;
        8'hE0: dx_crd_neg <= 10'b1001110001;
        8'hE1: dx_crd_neg <= 10'b0111010001;
        8'hE2: dx_crd_neg <= 10'b1011010001;
        8'hE3: dx_crd_neg <= 10'b1100011110;
        8'hE4: dx_crd_neg <= 10'b1101010001;
        8'hE5: dx_crd_neg <= 10'b1010011110;
        8'hE6: dx_crd_neg <= 10'b0110011110;
        8'hE7: dx_crd_neg <= 10'b1110001110;
        8'hE8: dx_crd_neg <= 10'b1110010001;
        8'hE9: dx_crd_neg <= 10'b1001011110;
        8'hEA: dx_crd_neg <= 10'b0101011110;
        8'hEB: dx_crd_neg <= 10'b1101001110;
        8'hEC: dx_crd_neg <= 10'b0011011110;
        8'hED: dx_crd_neg <= 10'b1011001110;
        8'hEE: dx_crd_neg <= 10'b0111001110;
        8'hEF: dx_crd_neg <= 10'b0101110001;
        8'hF0: dx_crd_neg <= 10'b0110110001;
        8'hF1: dx_crd_neg <= 10'b1000110111;
        8'hF2: dx_crd_neg <= 10'b0100110111;
        8'hF3: dx_crd_neg <= 10'b1100101110;
        8'hF4: dx_crd_neg <= 10'b0010110111;
        8'hF5: dx_crd_neg <= 10'b1010101110;
        8'hF6: dx_crd_neg <= 10'b0110101110;
        8'hF7: dx_crd_neg <= 10'b1110100001;
        8'hF8: dx_crd_neg <= 10'b1100110001;
        8'hF9: dx_crd_neg <= 10'b1001101110;
        8'hFA: dx_crd_neg <= 10'b0101101110;
        8'hFB: dx_crd_neg <= 10'b1101100001;
        8'hFC: dx_crd_neg <= 10'b0011101110;
        8'hFD: dx_crd_neg <= 10'b1011100001;
        8'hFE: dx_crd_neg <= 10'b0111100001;
        default: dx_crd_neg <= 10'b1010110001;
        endcase

    always @ (posedge clk)
        case (eight_bit)
        8'h00: dx_crd_pos <= 10'b0110001011;
        8'h01: dx_crd_pos <= 10'b1000101011;
        8'h02: dx_crd_pos <= 10'b0100101011;
        8'h03: dx_crd_pos <= 10'b1100010100;
        8'h04: dx_crd_pos <= 10'b0010101011;
        8'h05: dx_crd_pos <= 10'b1010010100;
        8'h06: dx_crd_pos <= 10'b0110010100;
        8'h07: dx_crd_pos <= 10'b0001110100;
        8'h08: dx_crd_pos <= 10'b0001101011;
        8'h09: dx_crd_pos <= 10'b1001010100;
        8'h0A: dx_crd_pos <= 10'b0101010100;
        8'h0B: dx_crd_pos <= 10'b1101000100;
        8'h0C: dx_crd_pos <= 10'b0011010100;
        8'h0D: dx_crd_pos <= 10'b1011000100;
        8'h0E: dx_crd_pos <= 10'b0111000100;
        8'h0F: dx_crd_pos <= 10'b1010001011;
        8'h10: dx_crd_pos <= 10'b1001001011;
        8'h11: dx_crd_pos <= 10'b1000110100;
        8'h12: dx_crd_pos <= 10'b0100110100;
        8'h13: dx_crd_pos <= 10'b1100100100;
        8'h14: dx_crd_pos <= 10'b0010110100;
        8'h15: dx_crd_pos <= 10'b1010100100;
        8'h16: dx_crd_pos <= 10'b0110100100;
        8'h17: dx_crd_pos <= 10'b0001011011;
        8'h18: dx_crd_pos <= 10'b0011001011;
        8'h19: dx_crd_pos <= 10'b1001100100;
        8'h1A: dx_crd_pos <= 10'b0101100100;
        8'h1B: dx_crd_pos <= 10'b0010011011;
        8'h1C: dx_crd_pos <= 10'b0011100100;
        8'h1D: dx_crd_pos <= 10'b0100011011;
        8'h1E: dx_crd_pos <= 10'b1000011011;
        8'h1F: dx_crd_pos <= 10'b0101001011;
        8'h20: dx_crd_pos <= 10'b0110001001;
        8'h21: dx_crd_pos <= 10'b1000101001;
        8'h22: dx_crd_pos <= 10'b0100101001;
        8'h23: dx_crd_pos <= 10'b1100011001;
        8'h24: dx_crd_pos <= 10'b0010101001;
        8'h25: dx_crd_pos <= 10'b1010011001;
        8'h26: dx_crd_pos <= 10'b0110011001;
        8'h27: dx_crd_pos <= 10'b0001111001;
        8'h28: dx_crd_pos <= 10'b0001101001;
        8'h29: dx_crd_pos <= 10'b1001011001;
        8'h2A: dx_crd_pos <= 10'b0101011001;
        8'h2B: dx_crd_pos <= 10'b1101001001;
        8'h2C: dx_crd_pos <= 10'b0011011001;
        8'h2D: dx_crd_pos <= 10'b1011001001;
        8'h2E: dx_crd_pos <= 10'b0111001001;
        8'h2F: dx_crd_pos <= 10'b1010001001;
        8'h30: dx_crd_pos <= 10'b1001001001;
        8'h31: dx_crd_pos <= 10'b1000111001;
        8'h32: dx_crd_pos <= 10'b0100111001;
        8'h33: dx_crd_pos <= 10'b1100101001;
        8'h34: dx_crd_pos <= 10'b0010111001;
        8'h35: dx_crd_pos <= 10'b1010101001;
        8'h36: dx_crd_pos <= 10'b0110101001;
        8'h37: dx_crd_pos <= 10'b0001011001;
        8'h38: dx_crd_pos <= 10'b0011001001;
        8'h39: dx_crd_pos <= 10'b1001101001;
        8'h3A: dx_crd_pos <= 10'b0101101001;
        8'h3B: dx_crd_pos <= 10'b0010011001;
        8'h3C: dx_crd_pos <= 10'b0011101001;
        8'h3D: dx_crd_pos <= 10'b0100011001;
        8'h3E: dx_crd_pos <= 10'b1000011001;
        8'h3F: dx_crd_pos <= 10'b0101001001;
        8'h40: dx_crd_pos <= 10'b0110000101;
        8'h41: dx_crd_pos <= 10'b1000100101;
        8'h42: dx_crd_pos <= 10'b0100100101;
        8'h43: dx_crd_pos <= 10'b1100010101;
        8'h44: dx_crd_pos <= 10'b0010100101;
        8'h45: dx_crd_pos <= 10'b1010010101;
        8'h46: dx_crd_pos <= 10'b0110010101;
        8'h47: dx_crd_pos <= 10'b0001110101;
        8'h48: dx_crd_pos <= 10'b0001100101;
        8'h49: dx_crd_pos <= 10'b1001010101;
        8'h4A: dx_crd_pos <= 10'b0101010101;
        8'h4B: dx_crd_pos <= 10'b1101000101;
        8'h4C: dx_crd_pos <= 10'b0011010101;
        8'h4D: dx_crd_pos <= 10'b1011000101;
        8'h4E: dx_crd_pos <= 10'b0111000101;
        8'h4F: dx_crd_pos <= 10'b1010000101;
        8'h50: dx_crd_pos <= 10'b1001000101;
        8'h51: dx_crd_pos <= 10'b1000110101;
        8'h52: dx_crd_pos <= 10'b0100110101;
        8'h53: dx_crd_pos <= 10'b1100100101;
        8'h54: dx_crd_pos <= 10'b0010110101;
        8'h55: dx_crd_pos <= 10'b1010100101;
        8'h56: dx_crd_pos <= 10'b0110100101;
        8'h57: dx_crd_pos <= 10'b0001010101;
        8'h58: dx_crd_pos <= 10'b0011000101;
        8'h59: dx_crd_pos <= 10'b1001100101;
        8'h5A: dx_crd_pos <= 10'b0101100101;
        8'h5B: dx_crd_pos <= 10'b0010010101;
        8'h5C: dx_crd_pos <= 10'b0011100101;
        8'h5D: dx_crd_pos <= 10'b0100010101;
        8'h5E: dx_crd_pos <= 10'b1000010101;
        8'h5F: dx_crd_pos <= 10'b0101000101;
        8'h60: dx_crd_pos <= 10'b0110001100;
        8'h61: dx_crd_pos <= 10'b1000101100;
        8'h62: dx_crd_pos <= 10'b0100101100;
        8'h63: dx_crd_pos <= 10'b1100010011;
        8'h64: dx_crd_pos <= 10'b0010101100;
        8'h65: dx_crd_pos <= 10'b1010010011;
        8'h66: dx_crd_pos <= 10'b0110010011;
        8'h67: dx_crd_pos <= 10'b0001110011;
        8'h68: dx_crd_pos <= 10'b0001101100;
        8'h69: dx_crd_pos <= 10'b1001010011;
        8'h6A: dx_crd_pos <= 10'b0101010011;
        8'h6B: dx_crd_pos <= 10'b1101000011;
        8'h6C: dx_crd_pos <= 10'b0011010011;
        8'h6D: dx_crd_pos <= 10'b1011000011;
        8'h6E: dx_crd_pos <= 10'b0111000011;
        8'h6F: dx_crd_pos <= 10'b1010001100;
        8'h70: dx_crd_pos <= 10'b1001001100;
        8'h71: dx_crd_pos <= 10'b1000110011;
        8'h72: dx_crd_pos <= 10'b0100110011;
        8'h73: dx_crd_pos <= 10'b1100100011;
        8'h74: dx_crd_pos <= 10'b0010110011;
        8'h75: dx_crd_pos <= 10'b1010100011;
        8'h76: dx_crd_pos <= 10'b0110100011;
        8'h77: dx_crd_pos <= 10'b0001011100;
        8'h78: dx_crd_pos <= 10'b0011001100;
        8'h79: dx_crd_pos <= 10'b1001100011;
        8'h7A: dx_crd_pos <= 10'b0101100011;
        8'h7B: dx_crd_pos <= 10'b0010011100;
        8'h7C: dx_crd_pos <= 10'b0011100011;
        8'h7D: dx_crd_pos <= 10'b0100011100;
        8'h7E: dx_crd_pos <= 10'b1000011100;
        8'h7F: dx_crd_pos <= 10'b0101001100;
        8'h80: dx_crd_pos <= 10'b0110001101;
        8'h81: dx_crd_pos <= 10'b1000101101;
        8'h82: dx_crd_pos <= 10'b0100101101;
        8'h83: dx_crd_pos <= 10'b1100010010;
        8'h84: dx_crd_pos <= 10'b0010101101;
        8'h85: dx_crd_pos <= 10'b1010010010;
        8'h86: dx_crd_pos <= 10'b0110010010;
        8'h87: dx_crd_pos <= 10'b0001110010;
        8'h88: dx_crd_pos <= 10'b0001101101;
        8'h89: dx_crd_pos <= 10'b1001010010;
        8'h8A: dx_crd_pos <= 10'b0101010010;
        8'h8B: dx_crd_pos <= 10'b1101000010;
        8'h8C: dx_crd_pos <= 10'b0011010010;
        8'h8D: dx_crd_pos <= 10'b1011000010;
        8'h8E: dx_crd_pos <= 10'b0111000010;
        8'h8F: dx_crd_pos <= 10'b1010001101;
        8'h90: dx_crd_pos <= 10'b1001001101;
        8'h91: dx_crd_pos <= 10'b1000110010;
        8'h92: dx_crd_pos <= 10'b0100110010;
        8'h93: dx_crd_pos <= 10'b1100100010;
        8'h94: dx_crd_pos <= 10'b0010110010;
        8'h95: dx_crd_pos <= 10'b1010100010;
        8'h96: dx_crd_pos <= 10'b0110100010;
        8'h97: dx_crd_pos <= 10'b0001011101;
        8'h98: dx_crd_pos <= 10'b0011001101;
        8'h99: dx_crd_pos <= 10'b1001100010;
        8'h9A: dx_crd_pos <= 10'b0101100010;
        8'h9B: dx_crd_pos <= 10'b0010011101;
        8'h9C: dx_crd_pos <= 10'b0011100010;
        8'h9D: dx_crd_pos <= 10'b0100011101;
        8'h9E: dx_crd_pos <= 10'b1000011101;
        8'h9F: dx_crd_pos <= 10'b0101001101;
        8'hA0: dx_crd_pos <= 10'b0110001010;
        8'hA1: dx_crd_pos <= 10'b1000101010;
        8'hA2: dx_crd_pos <= 10'b0100101010;
        8'hA3: dx_crd_pos <= 10'b1100011010;
        8'hA4: dx_crd_pos <= 10'b0010101010;
        8'hA5: dx_crd_pos <= 10'b1010011010;
        8'hA6: dx_crd_pos <= 10'b0110011010;
        8'hA7: dx_crd_pos <= 10'b0001111010;
        8'hA8: dx_crd_pos <= 10'b0001101010;
        8'hA9: dx_crd_pos <= 10'b1001011010;
        8'hAA: dx_crd_pos <= 10'b0101011010;
        8'hAB: dx_crd_pos <= 10'b1101001010;
        8'hAC: dx_crd_pos <= 10'b0011011010;
        8'hAD: dx_crd_pos <= 10'b1011001010;
        8'hAE: dx_crd_pos <= 10'b0111001010;
        8'hAF: dx_crd_pos <= 10'b1010001010;
        8'hB0: dx_crd_pos <= 10'b1001001010;
        8'hB1: dx_crd_pos <= 10'b1000111010;
        8'hB2: dx_crd_pos <= 10'b0100111010;
        8'hB3: dx_crd_pos <= 10'b1100101010;
        8'hB4: dx_crd_pos <= 10'b0010111010;
        8'hB5: dx_crd_pos <= 10'b1010101010;
        8'hB6: dx_crd_pos <= 10'b0110101010;
        8'hB7: dx_crd_pos <= 10'b0001011010;
        8'hB8: dx_crd_pos <= 10'b0011001010;
        8'hB9: dx_crd_pos <= 10'b1001101010;
        8'hBA: dx_crd_pos <= 10'b0101101010;
        8'hBB: dx_crd_pos <= 10'b0010011010;
        8'hBC: dx_crd_pos <= 10'b0011101010;
        8'hBD: dx_crd_pos <= 10'b0100011010;
        8'hBE: dx_crd_pos <= 10'b1000011010;
        8'hBF: dx_crd_pos <= 10'b0101001010;
        8'hC0: dx_crd_pos <= 10'b0110000110;
        8'hC1: dx_crd_pos <= 10'b1000100110;
        8'hC2: dx_crd_pos <= 10'b0100100110;
        8'hC3: dx_crd_pos <= 10'b1100010110;
        8'hC4: dx_crd_pos <= 10'b0010100110;
        8'hC5: dx_crd_pos <= 10'b1010010110;
        8'hC6: dx_crd_pos <= 10'b0110010110;
        8'hC7: dx_crd_pos <= 10'b0001110110;
        8'hC8: dx_crd_pos <= 10'b0001100110;
        8'hC9: dx_crd_pos <= 10'b1001010110;
        8'hCA: dx_crd_pos <= 10'b0101010110;
        8'hCB: dx_crd_pos <= 10'b1101000110;
        8'hCC: dx_crd_pos <= 10'b0011010110;
        8'hCD: dx_crd_pos <= 10'b1011000110;
        8'hCE: dx_crd_pos <= 10'b0111000110;
        8'hCF: dx_crd_pos <= 10'b1010000110;
        8'hD0: dx_crd_pos <= 10'b1001000110;
        8'hD1: dx_crd_pos <= 10'b1000110110;
        8'hD2: dx_crd_pos <= 10'b0100110110;
        8'hD3: dx_crd_pos <= 10'b1100100110;
        8'hD4: dx_crd_pos <= 10'b0010110110;
        8'hD5: dx_crd_pos <= 10'b1010100110;
        8'hD6: dx_crd_pos <= 10'b0110100110;
        8'hD7: dx_crd_pos <= 10'b0001010110;
        8'hD8: dx_crd_pos <= 10'b0011000110;
        8'hD9: dx_crd_pos <= 10'b1001100110;
        8'hDA: dx_crd_pos <= 10'b0101100110;
        8'hDB: dx_crd_pos <= 10'b0010010110;
        8'hDC: dx_crd_pos <= 10'b0011100110;
        8'hDD: dx_crd_pos <= 10'b0100010110;
        8'hDE: dx_crd_pos <= 10'b1000010110;
        8'hDF: dx_crd_pos <= 10'b0101000110;
        8'hE0: dx_crd_pos <= 10'b0110001110;
        8'hE1: dx_crd_pos <= 10'b1000101110;
        8'hE2: dx_crd_pos <= 10'b0100101110;
        8'hE3: dx_crd_pos <= 10'b1100010001;
        8'hE4: dx_crd_pos <= 10'b0010101110;
        8'hE5: dx_crd_pos <= 10'b1010010001;
        8'hE6: dx_crd_pos <= 10'b0110010001;
        8'hE7: dx_crd_pos <= 10'b0001110001;
        8'hE8: dx_crd_pos <= 10'b0001101110;
        8'hE9: dx_crd_pos <= 10'b1001010001;
        8'hEA: dx_crd_pos <= 10'b0101010001;
        8'hEB: dx_crd_pos <= 10'b1101001000;
        8'hEC: dx_crd_pos <= 10'b0011010001;
        8'hED: dx_crd_pos <= 10'b1011001000;
        8'hEE: dx_crd_pos <= 10'b0111001000;
        8'hEF: dx_crd_pos <= 10'b1010001110;
        8'hF0: dx_crd_pos <= 10'b1001001110;
        8'hF1: dx_crd_pos <= 10'b1000110001;
        8'hF2: dx_crd_pos <= 10'b0100110001;
        8'hF3: dx_crd_pos <= 10'b1100100001;
        8'hF4: dx_crd_pos <= 10'b0010110001;
        8'hF5: dx_crd_pos <= 10'b1010100001;
        8'hF6: dx_crd_pos <= 10'b0110100001;
        8'hF7: dx_crd_pos <= 10'b0001011110;
        8'hF8: dx_crd_pos <= 10'b0011001110;
        8'hF9: dx_crd_pos <= 10'b1001100001;
        8'hFA: dx_crd_pos <= 10'b0101100001;
        8'hFB: dx_crd_pos <= 10'b0010011110;
        8'hFC: dx_crd_pos <= 10'b0011100001;
        8'hFD: dx_crd_pos <= 10'b0100011110;
        8'hFE: dx_crd_pos <= 10'b1000011110;
        default: dx_crd_pos <= 10'b0101001110;
        endcase

    always @ (posedge clk)
        case (eight_bit)
        8'h1C: kx_crd_neg <= 10'b0011110100;
        8'h3C: kx_crd_neg <= 10'b0011111001;
        8'h5C: kx_crd_neg <= 10'b0011110101;
        8'h7C: kx_crd_neg <= 10'b0011110011;
        8'h9C: kx_crd_neg <= 10'b0011110010;
        8'hBC: kx_crd_neg <= 10'b0011111010;
        8'hDC: kx_crd_neg <= 10'b0011110110;
        8'hFC: kx_crd_neg <= 10'b0011111000;
        8'hF7: kx_crd_neg <= 10'b1110101000;
        8'hFB: kx_crd_neg <= 10'b1101101000;
        8'hFD: kx_crd_neg <= 10'b1011101000;
        8'hFE: kx_crd_neg <= 10'b0111101000;
        default: kx_crd_neg <= 10'd0;
        endcase

    always @ (posedge clk)
        case (eight_bit)
        8'h1C: kx_crd_pos <= 10'b1100001011;
        8'h3C: kx_crd_pos <= 10'b1100000110;
        8'h5C: kx_crd_pos <= 10'b1100001010;
        8'h7C: kx_crd_pos <= 10'b1100001100;
        8'h9C: kx_crd_pos <= 10'b1100001101;
        8'hBC: kx_crd_pos <= 10'b1100000101;
        8'hDC: kx_crd_pos <= 10'b1100001001;
        8'hFC: kx_crd_pos <= 10'b1100000111;
        8'hF7: kx_crd_pos <= 10'b0001010111;
        8'hFB: kx_crd_pos <= 10'b0010010111;
        8'hFD: kx_crd_pos <= 10'b0100010111;
        8'hFE: kx_crd_pos <= 10'b1000010111;
        default: kx_crd_pos <= 10'd0;
        endcase

endmodule
