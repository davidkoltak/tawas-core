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

module sgmii_8b10b_decode
(
    input clk,
    input rst,
    
    input sgmii_autoneg_start,
    
    input [9:0] ten_bit,
    
    output reg [7:0] eight_bit,
    output reg is_k,
    output reg disp_err
);

    reg [9:0] ten_bit_d1;
    reg [9:0] ten_bit_d2;
    reg [9:0] ten_bit_d3;
    
    always @ (posedge clk)
    begin
        ten_bit_d1 <= ten_bit;
        ten_bit_d2 <= ten_bit_d1;
        ten_bit_d3 <= ten_bit_d2;
    end
    
    reg [4:0] current_rd;
    wire [3:0] bit_cnt;
    
    assign bit_cnt = {3'd0, ten_bit_d3[9]} + {3'd0, ten_bit_d3[8]} + {3'd0, ten_bit_d3[7]} + 
                     {3'd0, ten_bit_d3[6]} + {3'd0, ten_bit_d3[5]} + {3'd0, ten_bit_d3[4]} + 
                     {3'd0, ten_bit_d3[3]} + {3'd0, ten_bit_d3[2]} + {3'd0, ten_bit_d3[1]} + 
                     {3'd0, ten_bit_d3[0]};
        
    always @ (posedge clk or posedge rst)
        if (rst)
            current_rd <= 5'd8;
        else if (!sgmii_autoneg_start)
            current_rd <= 5'd8;
        else
            current_rd <= current_rd + ({1'b0, bit_cnt} - 5'd5);

    always @ (posedge clk or posedge rst)
        if (rst)
            disp_err <= 1'b0;
        else if (!sgmii_autoneg_start)
            disp_err <= 1'b0;
        else
            disp_err <= disp_err | (current_rd[4]);
    
    always @ (posedge clk)
        case (ten_bit_d3)
        10'b0001010101: {is_k, eight_bit} <= {1'b0, 8'h57};
        10'b0001010110: {is_k, eight_bit} <= {1'b0, 8'hD7};
        10'b0001010111: {is_k, eight_bit} <= {1'b1, 8'hF7};
        10'b0001011001: {is_k, eight_bit} <= {1'b0, 8'h37};
        10'b0001011010: {is_k, eight_bit} <= {1'b0, 8'hB7};
        10'b0001011011: {is_k, eight_bit} <= {1'b0, 8'h17};
        10'b0001011100: {is_k, eight_bit} <= {1'b0, 8'h77};
        10'b0001011101: {is_k, eight_bit} <= {1'b0, 8'h97};
        10'b0001011110: {is_k, eight_bit} <= {1'b0, 8'hF7};
        10'b0001100101: {is_k, eight_bit} <= {1'b0, 8'h48};
        10'b0001100110: {is_k, eight_bit} <= {1'b0, 8'hC8};
        10'b0001101001: {is_k, eight_bit} <= {1'b0, 8'h28};
        10'b0001101010: {is_k, eight_bit} <= {1'b0, 8'hA8};
        10'b0001101011: {is_k, eight_bit} <= {1'b0, 8'h08};
        10'b0001101100: {is_k, eight_bit} <= {1'b0, 8'h68};
        10'b0001101101: {is_k, eight_bit} <= {1'b0, 8'h88};
        10'b0001101110: {is_k, eight_bit} <= {1'b0, 8'hE8};
        10'b0001110001: {is_k, eight_bit} <= {1'b0, 8'hE7};
        10'b0001110010: {is_k, eight_bit} <= {1'b0, 8'h87};
        10'b0001110011: {is_k, eight_bit} <= {1'b0, 8'h67};
        10'b0001110100: {is_k, eight_bit} <= {1'b0, 8'h07};
        10'b0001110101: {is_k, eight_bit} <= {1'b0, 8'h47};
        10'b0001110110: {is_k, eight_bit} <= {1'b0, 8'hC7};
        10'b0001111001: {is_k, eight_bit} <= {1'b0, 8'h27};
        10'b0001111010: {is_k, eight_bit} <= {1'b0, 8'hA7};
        10'b0010010101: {is_k, eight_bit} <= {1'b0, 8'h5B};
        10'b0010010110: {is_k, eight_bit} <= {1'b0, 8'hDB};
        10'b0010010111: {is_k, eight_bit} <= {1'b1, 8'hFB};
        10'b0010011001: {is_k, eight_bit} <= {1'b0, 8'h3B};
        10'b0010011010: {is_k, eight_bit} <= {1'b0, 8'hBB};
        10'b0010011011: {is_k, eight_bit} <= {1'b0, 8'h1B};
        10'b0010011100: {is_k, eight_bit} <= {1'b0, 8'h7B};
        10'b0010011101: {is_k, eight_bit} <= {1'b0, 8'h9B};
        10'b0010011110: {is_k, eight_bit} <= {1'b0, 8'hFB};
        10'b0010100101: {is_k, eight_bit} <= {1'b0, 8'h44};
        10'b0010100110: {is_k, eight_bit} <= {1'b0, 8'hC4};
        10'b0010101001: {is_k, eight_bit} <= {1'b0, 8'h24};
        10'b0010101010: {is_k, eight_bit} <= {1'b0, 8'hA4};
        10'b0010101011: {is_k, eight_bit} <= {1'b0, 8'h04};
        10'b0010101100: {is_k, eight_bit} <= {1'b0, 8'h64};
        10'b0010101101: {is_k, eight_bit} <= {1'b0, 8'h84};
        10'b0010101110: {is_k, eight_bit} <= {1'b0, 8'hE4};
        10'b0010110001: {is_k, eight_bit} <= {1'b0, 8'hF4};
        10'b0010110010: {is_k, eight_bit} <= {1'b0, 8'h94};
        10'b0010110011: {is_k, eight_bit} <= {1'b0, 8'h74};
        10'b0010110100: {is_k, eight_bit} <= {1'b0, 8'h14};
        10'b0010110101: {is_k, eight_bit} <= {1'b0, 8'h54};
        10'b0010110110: {is_k, eight_bit} <= {1'b0, 8'hD4};
        10'b0010110111: {is_k, eight_bit} <= {1'b0, 8'hF4};
        10'b0010111001: {is_k, eight_bit} <= {1'b0, 8'h34};
        10'b0010111010: {is_k, eight_bit} <= {1'b0, 8'hB4};
        10'b0010111011: {is_k, eight_bit} <= {1'b0, 8'h14};
        10'b0010111100: {is_k, eight_bit} <= {1'b0, 8'h74};
        10'b0010111101: {is_k, eight_bit} <= {1'b0, 8'h94};
        10'b0011000101: {is_k, eight_bit} <= {1'b0, 8'h58};
        10'b0011000110: {is_k, eight_bit} <= {1'b0, 8'hD8};
        10'b0011001001: {is_k, eight_bit} <= {1'b0, 8'h38};
        10'b0011001010: {is_k, eight_bit} <= {1'b0, 8'hB8};
        10'b0011001011: {is_k, eight_bit} <= {1'b0, 8'h18};
        10'b0011001100: {is_k, eight_bit} <= {1'b0, 8'h78};
        10'b0011001101: {is_k, eight_bit} <= {1'b0, 8'h98};
        10'b0011001110: {is_k, eight_bit} <= {1'b0, 8'hF8};
        10'b0011010001: {is_k, eight_bit} <= {1'b0, 8'hEC};
        10'b0011010010: {is_k, eight_bit} <= {1'b0, 8'h8C};
        10'b0011010011: {is_k, eight_bit} <= {1'b0, 8'h6C};
        10'b0011010100: {is_k, eight_bit} <= {1'b0, 8'h0C};
        10'b0011010101: {is_k, eight_bit} <= {1'b0, 8'h4C};
        10'b0011010110: {is_k, eight_bit} <= {1'b0, 8'hCC};
        10'b0011011001: {is_k, eight_bit} <= {1'b0, 8'h2C};
        10'b0011011010: {is_k, eight_bit} <= {1'b0, 8'hAC};
        10'b0011011011: {is_k, eight_bit} <= {1'b0, 8'h0C};
        10'b0011011100: {is_k, eight_bit} <= {1'b0, 8'h6C};
        10'b0011011101: {is_k, eight_bit} <= {1'b0, 8'h8C};
        10'b0011011110: {is_k, eight_bit} <= {1'b0, 8'hEC};
        10'b0011100001: {is_k, eight_bit} <= {1'b0, 8'hFC};
        10'b0011100010: {is_k, eight_bit} <= {1'b0, 8'h9C};
        10'b0011100011: {is_k, eight_bit} <= {1'b0, 8'h7C};
        10'b0011100100: {is_k, eight_bit} <= {1'b0, 8'h1C};
        10'b0011100101: {is_k, eight_bit} <= {1'b0, 8'h5C};
        10'b0011100110: {is_k, eight_bit} <= {1'b0, 8'hDC};
        10'b0011101001: {is_k, eight_bit} <= {1'b0, 8'h3C};
        10'b0011101010: {is_k, eight_bit} <= {1'b0, 8'hBC};
        10'b0011101011: {is_k, eight_bit} <= {1'b0, 8'h1C};
        10'b0011101100: {is_k, eight_bit} <= {1'b0, 8'h7C};
        10'b0011101101: {is_k, eight_bit} <= {1'b0, 8'h9C};
        10'b0011101110: {is_k, eight_bit} <= {1'b0, 8'hFC};
        10'b0011110010: {is_k, eight_bit} <= {1'b1, 8'h9C};
        10'b0011110011: {is_k, eight_bit} <= {1'b1, 8'h7C};
        10'b0011110100: {is_k, eight_bit} <= {1'b1, 8'h1C};
        10'b0011110101: {is_k, eight_bit} <= {1'b1, 8'h5C};
        10'b0011110110: {is_k, eight_bit} <= {1'b1, 8'hDC};
        10'b0011111000: {is_k, eight_bit} <= {1'b1, 8'hFC};
        10'b0011111001: {is_k, eight_bit} <= {1'b1, 8'h3C};
        10'b0011111010: {is_k, eight_bit} <= {1'b1, 8'hBC};
        10'b0100010101: {is_k, eight_bit} <= {1'b0, 8'h5D};
        10'b0100010110: {is_k, eight_bit} <= {1'b0, 8'hDD};
        10'b0100010111: {is_k, eight_bit} <= {1'b1, 8'hFD};
        10'b0100011001: {is_k, eight_bit} <= {1'b0, 8'h3D};
        10'b0100011010: {is_k, eight_bit} <= {1'b0, 8'hBD};
        10'b0100011011: {is_k, eight_bit} <= {1'b0, 8'h1D};
        10'b0100011100: {is_k, eight_bit} <= {1'b0, 8'h7D};
        10'b0100011101: {is_k, eight_bit} <= {1'b0, 8'h9D};
        10'b0100011110: {is_k, eight_bit} <= {1'b0, 8'hFD};
        10'b0100100101: {is_k, eight_bit} <= {1'b0, 8'h42};
        10'b0100100110: {is_k, eight_bit} <= {1'b0, 8'hC2};
        10'b0100101001: {is_k, eight_bit} <= {1'b0, 8'h22};
        10'b0100101010: {is_k, eight_bit} <= {1'b0, 8'hA2};
        10'b0100101011: {is_k, eight_bit} <= {1'b0, 8'h02};
        10'b0100101100: {is_k, eight_bit} <= {1'b0, 8'h62};
        10'b0100101101: {is_k, eight_bit} <= {1'b0, 8'h82};
        10'b0100101110: {is_k, eight_bit} <= {1'b0, 8'hE2};
        10'b0100110001: {is_k, eight_bit} <= {1'b0, 8'hF2};
        10'b0100110010: {is_k, eight_bit} <= {1'b0, 8'h92};
        10'b0100110011: {is_k, eight_bit} <= {1'b0, 8'h72};
        10'b0100110100: {is_k, eight_bit} <= {1'b0, 8'h12};
        10'b0100110101: {is_k, eight_bit} <= {1'b0, 8'h52};
        10'b0100110110: {is_k, eight_bit} <= {1'b0, 8'hD2};
        10'b0100110111: {is_k, eight_bit} <= {1'b0, 8'hF2};
        10'b0100111001: {is_k, eight_bit} <= {1'b0, 8'h32};
        10'b0100111010: {is_k, eight_bit} <= {1'b0, 8'hB2};
        10'b0100111011: {is_k, eight_bit} <= {1'b0, 8'h12};
        10'b0100111100: {is_k, eight_bit} <= {1'b0, 8'h72};
        10'b0100111101: {is_k, eight_bit} <= {1'b0, 8'h92};
        10'b0101000101: {is_k, eight_bit} <= {1'b0, 8'h5F};
        10'b0101000110: {is_k, eight_bit} <= {1'b0, 8'hDF};
        10'b0101001001: {is_k, eight_bit} <= {1'b0, 8'h3F};
        10'b0101001010: {is_k, eight_bit} <= {1'b0, 8'hBF};
        10'b0101001011: {is_k, eight_bit} <= {1'b0, 8'h1F};
        10'b0101001100: {is_k, eight_bit} <= {1'b0, 8'h7F};
        10'b0101001101: {is_k, eight_bit} <= {1'b0, 8'h9F};
        10'b0101001110: {is_k, eight_bit} <= {1'b0, 8'hFF};
        10'b0101010001: {is_k, eight_bit} <= {1'b0, 8'hEA};
        10'b0101010010: {is_k, eight_bit} <= {1'b0, 8'h8A};
        10'b0101010011: {is_k, eight_bit} <= {1'b0, 8'h6A};
        10'b0101010100: {is_k, eight_bit} <= {1'b0, 8'h0A};
        10'b0101010101: {is_k, eight_bit} <= {1'b0, 8'h4A};
        10'b0101010110: {is_k, eight_bit} <= {1'b0, 8'hCA};
        10'b0101011001: {is_k, eight_bit} <= {1'b0, 8'h2A};
        10'b0101011010: {is_k, eight_bit} <= {1'b0, 8'hAA};
        10'b0101011011: {is_k, eight_bit} <= {1'b0, 8'h0A};
        10'b0101011100: {is_k, eight_bit} <= {1'b0, 8'h6A};
        10'b0101011101: {is_k, eight_bit} <= {1'b0, 8'h8A};
        10'b0101011110: {is_k, eight_bit} <= {1'b0, 8'hEA};
        10'b0101100001: {is_k, eight_bit} <= {1'b0, 8'hFA};
        10'b0101100010: {is_k, eight_bit} <= {1'b0, 8'h9A};
        10'b0101100011: {is_k, eight_bit} <= {1'b0, 8'h7A};
        10'b0101100100: {is_k, eight_bit} <= {1'b0, 8'h1A};
        10'b0101100101: {is_k, eight_bit} <= {1'b0, 8'h5A};
        10'b0101100110: {is_k, eight_bit} <= {1'b0, 8'hDA};
        10'b0101101001: {is_k, eight_bit} <= {1'b0, 8'h3A};
        10'b0101101010: {is_k, eight_bit} <= {1'b0, 8'hBA};
        10'b0101101011: {is_k, eight_bit} <= {1'b0, 8'h1A};
        10'b0101101100: {is_k, eight_bit} <= {1'b0, 8'h7A};
        10'b0101101101: {is_k, eight_bit} <= {1'b0, 8'h9A};
        10'b0101101110: {is_k, eight_bit} <= {1'b0, 8'hFA};
        10'b0101110001: {is_k, eight_bit} <= {1'b0, 8'hEF};
        10'b0101110010: {is_k, eight_bit} <= {1'b0, 8'h8F};
        10'b0101110011: {is_k, eight_bit} <= {1'b0, 8'h6F};
        10'b0101110100: {is_k, eight_bit} <= {1'b0, 8'h0F};
        10'b0101110101: {is_k, eight_bit} <= {1'b0, 8'h4F};
        10'b0101110110: {is_k, eight_bit} <= {1'b0, 8'hCF};
        10'b0101111001: {is_k, eight_bit} <= {1'b0, 8'h2F};
        10'b0101111010: {is_k, eight_bit} <= {1'b0, 8'hAF};
        10'b0110000101: {is_k, eight_bit} <= {1'b0, 8'h40};
        10'b0110000110: {is_k, eight_bit} <= {1'b0, 8'hC0};
        10'b0110001001: {is_k, eight_bit} <= {1'b0, 8'h20};
        10'b0110001010: {is_k, eight_bit} <= {1'b0, 8'hA0};
        10'b0110001011: {is_k, eight_bit} <= {1'b0, 8'h00};
        10'b0110001100: {is_k, eight_bit} <= {1'b0, 8'h60};
        10'b0110001101: {is_k, eight_bit} <= {1'b0, 8'h80};
        10'b0110001110: {is_k, eight_bit} <= {1'b0, 8'hE0};
        10'b0110010001: {is_k, eight_bit} <= {1'b0, 8'hE6};
        10'b0110010010: {is_k, eight_bit} <= {1'b0, 8'h86};
        10'b0110010011: {is_k, eight_bit} <= {1'b0, 8'h66};
        10'b0110010100: {is_k, eight_bit} <= {1'b0, 8'h06};
        10'b0110010101: {is_k, eight_bit} <= {1'b0, 8'h46};
        10'b0110010110: {is_k, eight_bit} <= {1'b0, 8'hC6};
        10'b0110011001: {is_k, eight_bit} <= {1'b0, 8'h26};
        10'b0110011010: {is_k, eight_bit} <= {1'b0, 8'hA6};
        10'b0110011011: {is_k, eight_bit} <= {1'b0, 8'h06};
        10'b0110011100: {is_k, eight_bit} <= {1'b0, 8'h66};
        10'b0110011101: {is_k, eight_bit} <= {1'b0, 8'h86};
        10'b0110011110: {is_k, eight_bit} <= {1'b0, 8'hE6};
        10'b0110100001: {is_k, eight_bit} <= {1'b0, 8'hF6};
        10'b0110100010: {is_k, eight_bit} <= {1'b0, 8'h96};
        10'b0110100011: {is_k, eight_bit} <= {1'b0, 8'h76};
        10'b0110100100: {is_k, eight_bit} <= {1'b0, 8'h16};
        10'b0110100101: {is_k, eight_bit} <= {1'b0, 8'h56};
        10'b0110100110: {is_k, eight_bit} <= {1'b0, 8'hD6};
        10'b0110101001: {is_k, eight_bit} <= {1'b0, 8'h36};
        10'b0110101010: {is_k, eight_bit} <= {1'b0, 8'hB6};
        10'b0110101011: {is_k, eight_bit} <= {1'b0, 8'h16};
        10'b0110101100: {is_k, eight_bit} <= {1'b0, 8'h76};
        10'b0110101101: {is_k, eight_bit} <= {1'b0, 8'h96};
        10'b0110101110: {is_k, eight_bit} <= {1'b0, 8'hF6};
        10'b0110110001: {is_k, eight_bit} <= {1'b0, 8'hF0};
        10'b0110110010: {is_k, eight_bit} <= {1'b0, 8'h90};
        10'b0110110011: {is_k, eight_bit} <= {1'b0, 8'h70};
        10'b0110110100: {is_k, eight_bit} <= {1'b0, 8'h10};
        10'b0110110101: {is_k, eight_bit} <= {1'b0, 8'h50};
        10'b0110110110: {is_k, eight_bit} <= {1'b0, 8'hD0};
        10'b0110111001: {is_k, eight_bit} <= {1'b0, 8'h30};
        10'b0110111010: {is_k, eight_bit} <= {1'b0, 8'hB0};
        10'b0111000010: {is_k, eight_bit} <= {1'b0, 8'h8E};
        10'b0111000011: {is_k, eight_bit} <= {1'b0, 8'h6E};
        10'b0111000100: {is_k, eight_bit} <= {1'b0, 8'h0E};
        10'b0111000101: {is_k, eight_bit} <= {1'b0, 8'h4E};
        10'b0111000110: {is_k, eight_bit} <= {1'b0, 8'hCE};
        10'b0111001000: {is_k, eight_bit} <= {1'b0, 8'hEE};
        10'b0111001001: {is_k, eight_bit} <= {1'b0, 8'h2E};
        10'b0111001010: {is_k, eight_bit} <= {1'b0, 8'hAE};
        10'b0111001011: {is_k, eight_bit} <= {1'b0, 8'h0E};
        10'b0111001100: {is_k, eight_bit} <= {1'b0, 8'h6E};
        10'b0111001101: {is_k, eight_bit} <= {1'b0, 8'h8E};
        10'b0111001110: {is_k, eight_bit} <= {1'b0, 8'hEE};
        10'b0111010001: {is_k, eight_bit} <= {1'b0, 8'hE1};
        10'b0111010010: {is_k, eight_bit} <= {1'b0, 8'h81};
        10'b0111010011: {is_k, eight_bit} <= {1'b0, 8'h61};
        10'b0111010100: {is_k, eight_bit} <= {1'b0, 8'h01};
        10'b0111010101: {is_k, eight_bit} <= {1'b0, 8'h41};
        10'b0111010110: {is_k, eight_bit} <= {1'b0, 8'hC1};
        10'b0111011001: {is_k, eight_bit} <= {1'b0, 8'h21};
        10'b0111011010: {is_k, eight_bit} <= {1'b0, 8'hA1};
        10'b0111100001: {is_k, eight_bit} <= {1'b0, 8'hFE};
        10'b0111100010: {is_k, eight_bit} <= {1'b0, 8'h9E};
        10'b0111100011: {is_k, eight_bit} <= {1'b0, 8'h7E};
        10'b0111100100: {is_k, eight_bit} <= {1'b0, 8'h1E};
        10'b0111100101: {is_k, eight_bit} <= {1'b0, 8'h5E};
        10'b0111100110: {is_k, eight_bit} <= {1'b0, 8'hDE};
        10'b0111101000: {is_k, eight_bit} <= {1'b1, 8'hFE};
        10'b0111101001: {is_k, eight_bit} <= {1'b0, 8'h3E};
        10'b0111101010: {is_k, eight_bit} <= {1'b0, 8'hBE};
        10'b1000010101: {is_k, eight_bit} <= {1'b0, 8'h5E};
        10'b1000010110: {is_k, eight_bit} <= {1'b0, 8'hDE};
        10'b1000010111: {is_k, eight_bit} <= {1'b1, 8'hFE};
        10'b1000011001: {is_k, eight_bit} <= {1'b0, 8'h3E};
        10'b1000011010: {is_k, eight_bit} <= {1'b0, 8'hBE};
        10'b1000011011: {is_k, eight_bit} <= {1'b0, 8'h1E};
        10'b1000011100: {is_k, eight_bit} <= {1'b0, 8'h7E};
        10'b1000011101: {is_k, eight_bit} <= {1'b0, 8'h9E};
        10'b1000011110: {is_k, eight_bit} <= {1'b0, 8'hFE};
        10'b1000100101: {is_k, eight_bit} <= {1'b0, 8'h41};
        10'b1000100110: {is_k, eight_bit} <= {1'b0, 8'hC1};
        10'b1000101001: {is_k, eight_bit} <= {1'b0, 8'h21};
        10'b1000101010: {is_k, eight_bit} <= {1'b0, 8'hA1};
        10'b1000101011: {is_k, eight_bit} <= {1'b0, 8'h01};
        10'b1000101100: {is_k, eight_bit} <= {1'b0, 8'h61};
        10'b1000101101: {is_k, eight_bit} <= {1'b0, 8'h81};
        10'b1000101110: {is_k, eight_bit} <= {1'b0, 8'hE1};
        10'b1000110001: {is_k, eight_bit} <= {1'b0, 8'hF1};
        10'b1000110010: {is_k, eight_bit} <= {1'b0, 8'h91};
        10'b1000110011: {is_k, eight_bit} <= {1'b0, 8'h71};
        10'b1000110100: {is_k, eight_bit} <= {1'b0, 8'h11};
        10'b1000110101: {is_k, eight_bit} <= {1'b0, 8'h51};
        10'b1000110110: {is_k, eight_bit} <= {1'b0, 8'hD1};
        10'b1000110111: {is_k, eight_bit} <= {1'b0, 8'hF1};
        10'b1000111001: {is_k, eight_bit} <= {1'b0, 8'h31};
        10'b1000111010: {is_k, eight_bit} <= {1'b0, 8'hB1};
        10'b1000111011: {is_k, eight_bit} <= {1'b0, 8'h11};
        10'b1000111100: {is_k, eight_bit} <= {1'b0, 8'h71};
        10'b1000111101: {is_k, eight_bit} <= {1'b0, 8'h91};
        10'b1001000101: {is_k, eight_bit} <= {1'b0, 8'h50};
        10'b1001000110: {is_k, eight_bit} <= {1'b0, 8'hD0};
        10'b1001001001: {is_k, eight_bit} <= {1'b0, 8'h30};
        10'b1001001010: {is_k, eight_bit} <= {1'b0, 8'hB0};
        10'b1001001011: {is_k, eight_bit} <= {1'b0, 8'h10};
        10'b1001001100: {is_k, eight_bit} <= {1'b0, 8'h70};
        10'b1001001101: {is_k, eight_bit} <= {1'b0, 8'h90};
        10'b1001001110: {is_k, eight_bit} <= {1'b0, 8'hF0};
        10'b1001010001: {is_k, eight_bit} <= {1'b0, 8'hE9};
        10'b1001010010: {is_k, eight_bit} <= {1'b0, 8'h89};
        10'b1001010011: {is_k, eight_bit} <= {1'b0, 8'h69};
        10'b1001010100: {is_k, eight_bit} <= {1'b0, 8'h09};
        10'b1001010101: {is_k, eight_bit} <= {1'b0, 8'h49};
        10'b1001010110: {is_k, eight_bit} <= {1'b0, 8'hC9};
        10'b1001011001: {is_k, eight_bit} <= {1'b0, 8'h29};
        10'b1001011010: {is_k, eight_bit} <= {1'b0, 8'hA9};
        10'b1001011011: {is_k, eight_bit} <= {1'b0, 8'h09};
        10'b1001011100: {is_k, eight_bit} <= {1'b0, 8'h69};
        10'b1001011101: {is_k, eight_bit} <= {1'b0, 8'h89};
        10'b1001011110: {is_k, eight_bit} <= {1'b0, 8'hE9};
        10'b1001100001: {is_k, eight_bit} <= {1'b0, 8'hF9};
        10'b1001100010: {is_k, eight_bit} <= {1'b0, 8'h99};
        10'b1001100011: {is_k, eight_bit} <= {1'b0, 8'h79};
        10'b1001100100: {is_k, eight_bit} <= {1'b0, 8'h19};
        10'b1001100101: {is_k, eight_bit} <= {1'b0, 8'h59};
        10'b1001100110: {is_k, eight_bit} <= {1'b0, 8'hD9};
        10'b1001101001: {is_k, eight_bit} <= {1'b0, 8'h39};
        10'b1001101010: {is_k, eight_bit} <= {1'b0, 8'hB9};
        10'b1001101011: {is_k, eight_bit} <= {1'b0, 8'h19};
        10'b1001101100: {is_k, eight_bit} <= {1'b0, 8'h79};
        10'b1001101101: {is_k, eight_bit} <= {1'b0, 8'h99};
        10'b1001101110: {is_k, eight_bit} <= {1'b0, 8'hF9};
        10'b1001110001: {is_k, eight_bit} <= {1'b0, 8'hE0};
        10'b1001110010: {is_k, eight_bit} <= {1'b0, 8'h80};
        10'b1001110011: {is_k, eight_bit} <= {1'b0, 8'h60};
        10'b1001110100: {is_k, eight_bit} <= {1'b0, 8'h00};
        10'b1001110101: {is_k, eight_bit} <= {1'b0, 8'h40};
        10'b1001110110: {is_k, eight_bit} <= {1'b0, 8'hC0};
        10'b1001111001: {is_k, eight_bit} <= {1'b0, 8'h20};
        10'b1001111010: {is_k, eight_bit} <= {1'b0, 8'hA0};
        10'b1010000101: {is_k, eight_bit} <= {1'b0, 8'h4F};
        10'b1010000110: {is_k, eight_bit} <= {1'b0, 8'hCF};
        10'b1010001001: {is_k, eight_bit} <= {1'b0, 8'h2F};
        10'b1010001010: {is_k, eight_bit} <= {1'b0, 8'hAF};
        10'b1010001011: {is_k, eight_bit} <= {1'b0, 8'h0F};
        10'b1010001100: {is_k, eight_bit} <= {1'b0, 8'h6F};
        10'b1010001101: {is_k, eight_bit} <= {1'b0, 8'h8F};
        10'b1010001110: {is_k, eight_bit} <= {1'b0, 8'hEF};
        10'b1010010001: {is_k, eight_bit} <= {1'b0, 8'hE5};
        10'b1010010010: {is_k, eight_bit} <= {1'b0, 8'h85};
        10'b1010010011: {is_k, eight_bit} <= {1'b0, 8'h65};
        10'b1010010100: {is_k, eight_bit} <= {1'b0, 8'h05};
        10'b1010010101: {is_k, eight_bit} <= {1'b0, 8'h45};
        10'b1010010110: {is_k, eight_bit} <= {1'b0, 8'hC5};
        10'b1010011001: {is_k, eight_bit} <= {1'b0, 8'h25};
        10'b1010011010: {is_k, eight_bit} <= {1'b0, 8'hA5};
        10'b1010011011: {is_k, eight_bit} <= {1'b0, 8'h05};
        10'b1010011100: {is_k, eight_bit} <= {1'b0, 8'h65};
        10'b1010011101: {is_k, eight_bit} <= {1'b0, 8'h85};
        10'b1010011110: {is_k, eight_bit} <= {1'b0, 8'hE5};
        10'b1010100001: {is_k, eight_bit} <= {1'b0, 8'hF5};
        10'b1010100010: {is_k, eight_bit} <= {1'b0, 8'h95};
        10'b1010100011: {is_k, eight_bit} <= {1'b0, 8'h75};
        10'b1010100100: {is_k, eight_bit} <= {1'b0, 8'h15};
        10'b1010100101: {is_k, eight_bit} <= {1'b0, 8'h55};
        10'b1010100110: {is_k, eight_bit} <= {1'b0, 8'hD5};
        10'b1010101001: {is_k, eight_bit} <= {1'b0, 8'h35};
        10'b1010101010: {is_k, eight_bit} <= {1'b0, 8'hB5};
        10'b1010101011: {is_k, eight_bit} <= {1'b0, 8'h15};
        10'b1010101100: {is_k, eight_bit} <= {1'b0, 8'h75};
        10'b1010101101: {is_k, eight_bit} <= {1'b0, 8'h95};
        10'b1010101110: {is_k, eight_bit} <= {1'b0, 8'hF5};
        10'b1010110001: {is_k, eight_bit} <= {1'b0, 8'hFF};
        10'b1010110010: {is_k, eight_bit} <= {1'b0, 8'h9F};
        10'b1010110011: {is_k, eight_bit} <= {1'b0, 8'h7F};
        10'b1010110100: {is_k, eight_bit} <= {1'b0, 8'h1F};
        10'b1010110101: {is_k, eight_bit} <= {1'b0, 8'h5F};
        10'b1010110110: {is_k, eight_bit} <= {1'b0, 8'hDF};
        10'b1010111001: {is_k, eight_bit} <= {1'b0, 8'h3F};
        10'b1010111010: {is_k, eight_bit} <= {1'b0, 8'hBF};
        10'b1011000010: {is_k, eight_bit} <= {1'b0, 8'h8D};
        10'b1011000011: {is_k, eight_bit} <= {1'b0, 8'h6D};
        10'b1011000100: {is_k, eight_bit} <= {1'b0, 8'h0D};
        10'b1011000101: {is_k, eight_bit} <= {1'b0, 8'h4D};
        10'b1011000110: {is_k, eight_bit} <= {1'b0, 8'hCD};
        10'b1011001000: {is_k, eight_bit} <= {1'b0, 8'hED};
        10'b1011001001: {is_k, eight_bit} <= {1'b0, 8'h2D};
        10'b1011001010: {is_k, eight_bit} <= {1'b0, 8'hAD};
        10'b1011001011: {is_k, eight_bit} <= {1'b0, 8'h0D};
        10'b1011001100: {is_k, eight_bit} <= {1'b0, 8'h6D};
        10'b1011001101: {is_k, eight_bit} <= {1'b0, 8'h8D};
        10'b1011001110: {is_k, eight_bit} <= {1'b0, 8'hED};
        10'b1011010001: {is_k, eight_bit} <= {1'b0, 8'hE2};
        10'b1011010010: {is_k, eight_bit} <= {1'b0, 8'h82};
        10'b1011010011: {is_k, eight_bit} <= {1'b0, 8'h62};
        10'b1011010100: {is_k, eight_bit} <= {1'b0, 8'h02};
        10'b1011010101: {is_k, eight_bit} <= {1'b0, 8'h42};
        10'b1011010110: {is_k, eight_bit} <= {1'b0, 8'hC2};
        10'b1011011001: {is_k, eight_bit} <= {1'b0, 8'h22};
        10'b1011011010: {is_k, eight_bit} <= {1'b0, 8'hA2};
        10'b1011100001: {is_k, eight_bit} <= {1'b0, 8'hFD};
        10'b1011100010: {is_k, eight_bit} <= {1'b0, 8'h9D};
        10'b1011100011: {is_k, eight_bit} <= {1'b0, 8'h7D};
        10'b1011100100: {is_k, eight_bit} <= {1'b0, 8'h1D};
        10'b1011100101: {is_k, eight_bit} <= {1'b0, 8'h5D};
        10'b1011100110: {is_k, eight_bit} <= {1'b0, 8'hDD};
        10'b1011101000: {is_k, eight_bit} <= {1'b1, 8'hFD};
        10'b1011101001: {is_k, eight_bit} <= {1'b0, 8'h3D};
        10'b1011101010: {is_k, eight_bit} <= {1'b0, 8'hBD};
        10'b1100000101: {is_k, eight_bit} <= {1'b1, 8'hBC};
        10'b1100000110: {is_k, eight_bit} <= {1'b1, 8'h3C};
        10'b1100000111: {is_k, eight_bit} <= {1'b1, 8'hFC};
        10'b1100001001: {is_k, eight_bit} <= {1'b1, 8'hDC};
        10'b1100001010: {is_k, eight_bit} <= {1'b1, 8'h5C};
        10'b1100001011: {is_k, eight_bit} <= {1'b1, 8'h1C};
        10'b1100001100: {is_k, eight_bit} <= {1'b1, 8'h7C};
        10'b1100001101: {is_k, eight_bit} <= {1'b1, 8'h9C};
        10'b1100010001: {is_k, eight_bit} <= {1'b0, 8'hE3};
        10'b1100010010: {is_k, eight_bit} <= {1'b0, 8'h83};
        10'b1100010011: {is_k, eight_bit} <= {1'b0, 8'h63};
        10'b1100010100: {is_k, eight_bit} <= {1'b0, 8'h03};
        10'b1100010101: {is_k, eight_bit} <= {1'b0, 8'h43};
        10'b1100010110: {is_k, eight_bit} <= {1'b0, 8'hC3};
        10'b1100011001: {is_k, eight_bit} <= {1'b0, 8'h23};
        10'b1100011010: {is_k, eight_bit} <= {1'b0, 8'hA3};
        10'b1100011011: {is_k, eight_bit} <= {1'b0, 8'h03};
        10'b1100011100: {is_k, eight_bit} <= {1'b0, 8'h63};
        10'b1100011101: {is_k, eight_bit} <= {1'b0, 8'h83};
        10'b1100011110: {is_k, eight_bit} <= {1'b0, 8'hE3};
        10'b1100100001: {is_k, eight_bit} <= {1'b0, 8'hF3};
        10'b1100100010: {is_k, eight_bit} <= {1'b0, 8'h93};
        10'b1100100011: {is_k, eight_bit} <= {1'b0, 8'h73};
        10'b1100100100: {is_k, eight_bit} <= {1'b0, 8'h13};
        10'b1100100101: {is_k, eight_bit} <= {1'b0, 8'h53};
        10'b1100100110: {is_k, eight_bit} <= {1'b0, 8'hD3};
        10'b1100101001: {is_k, eight_bit} <= {1'b0, 8'h33};
        10'b1100101010: {is_k, eight_bit} <= {1'b0, 8'hB3};
        10'b1100101011: {is_k, eight_bit} <= {1'b0, 8'h13};
        10'b1100101100: {is_k, eight_bit} <= {1'b0, 8'h73};
        10'b1100101101: {is_k, eight_bit} <= {1'b0, 8'h93};
        10'b1100101110: {is_k, eight_bit} <= {1'b0, 8'hF3};
        10'b1100110001: {is_k, eight_bit} <= {1'b0, 8'hF8};
        10'b1100110010: {is_k, eight_bit} <= {1'b0, 8'h98};
        10'b1100110011: {is_k, eight_bit} <= {1'b0, 8'h78};
        10'b1100110100: {is_k, eight_bit} <= {1'b0, 8'h18};
        10'b1100110101: {is_k, eight_bit} <= {1'b0, 8'h58};
        10'b1100110110: {is_k, eight_bit} <= {1'b0, 8'hD8};
        10'b1100111001: {is_k, eight_bit} <= {1'b0, 8'h38};
        10'b1100111010: {is_k, eight_bit} <= {1'b0, 8'hB8};
        10'b1101000010: {is_k, eight_bit} <= {1'b0, 8'h8B};
        10'b1101000011: {is_k, eight_bit} <= {1'b0, 8'h6B};
        10'b1101000100: {is_k, eight_bit} <= {1'b0, 8'h0B};
        10'b1101000101: {is_k, eight_bit} <= {1'b0, 8'h4B};
        10'b1101000110: {is_k, eight_bit} <= {1'b0, 8'hCB};
        10'b1101001000: {is_k, eight_bit} <= {1'b0, 8'hEB};
        10'b1101001001: {is_k, eight_bit} <= {1'b0, 8'h2B};
        10'b1101001010: {is_k, eight_bit} <= {1'b0, 8'hAB};
        10'b1101001011: {is_k, eight_bit} <= {1'b0, 8'h0B};
        10'b1101001100: {is_k, eight_bit} <= {1'b0, 8'h6B};
        10'b1101001101: {is_k, eight_bit} <= {1'b0, 8'h8B};
        10'b1101001110: {is_k, eight_bit} <= {1'b0, 8'hEB};
        10'b1101010001: {is_k, eight_bit} <= {1'b0, 8'hE4};
        10'b1101010010: {is_k, eight_bit} <= {1'b0, 8'h84};
        10'b1101010011: {is_k, eight_bit} <= {1'b0, 8'h64};
        10'b1101010100: {is_k, eight_bit} <= {1'b0, 8'h04};
        10'b1101010101: {is_k, eight_bit} <= {1'b0, 8'h44};
        10'b1101010110: {is_k, eight_bit} <= {1'b0, 8'hC4};
        10'b1101011001: {is_k, eight_bit} <= {1'b0, 8'h24};
        10'b1101011010: {is_k, eight_bit} <= {1'b0, 8'hA4};
        10'b1101100001: {is_k, eight_bit} <= {1'b0, 8'hFB};
        10'b1101100010: {is_k, eight_bit} <= {1'b0, 8'h9B};
        10'b1101100011: {is_k, eight_bit} <= {1'b0, 8'h7B};
        10'b1101100100: {is_k, eight_bit} <= {1'b0, 8'h1B};
        10'b1101100101: {is_k, eight_bit} <= {1'b0, 8'h5B};
        10'b1101100110: {is_k, eight_bit} <= {1'b0, 8'hDB};
        10'b1101101000: {is_k, eight_bit} <= {1'b1, 8'hFB};
        10'b1101101001: {is_k, eight_bit} <= {1'b0, 8'h3B};
        10'b1101101010: {is_k, eight_bit} <= {1'b0, 8'hBB};
        10'b1110000101: {is_k, eight_bit} <= {1'b0, 8'h47};
        10'b1110000110: {is_k, eight_bit} <= {1'b0, 8'hC7};
        10'b1110001001: {is_k, eight_bit} <= {1'b0, 8'h27};
        10'b1110001010: {is_k, eight_bit} <= {1'b0, 8'hA7};
        10'b1110001011: {is_k, eight_bit} <= {1'b0, 8'h07};
        10'b1110001100: {is_k, eight_bit} <= {1'b0, 8'h67};
        10'b1110001101: {is_k, eight_bit} <= {1'b0, 8'h87};
        10'b1110001110: {is_k, eight_bit} <= {1'b0, 8'hE7};
        10'b1110010001: {is_k, eight_bit} <= {1'b0, 8'hE8};
        10'b1110010010: {is_k, eight_bit} <= {1'b0, 8'h88};
        10'b1110010011: {is_k, eight_bit} <= {1'b0, 8'h68};
        10'b1110010100: {is_k, eight_bit} <= {1'b0, 8'h08};
        10'b1110010101: {is_k, eight_bit} <= {1'b0, 8'h48};
        10'b1110010110: {is_k, eight_bit} <= {1'b0, 8'hC8};
        10'b1110011001: {is_k, eight_bit} <= {1'b0, 8'h28};
        10'b1110011010: {is_k, eight_bit} <= {1'b0, 8'hA8};
        10'b1110100001: {is_k, eight_bit} <= {1'b0, 8'hF7};
        10'b1110100010: {is_k, eight_bit} <= {1'b0, 8'h97};
        10'b1110100011: {is_k, eight_bit} <= {1'b0, 8'h77};
        10'b1110100100: {is_k, eight_bit} <= {1'b0, 8'h17};
        10'b1110100101: {is_k, eight_bit} <= {1'b0, 8'h57};
        10'b1110100110: {is_k, eight_bit} <= {1'b0, 8'hD7};
        10'b1110101000: {is_k, eight_bit} <= {1'b1, 8'hF7};
        10'b1110101001: {is_k, eight_bit} <= {1'b0, 8'h37};
        10'b1110101010: {is_k, eight_bit} <= {1'b0, 8'hB7};

        default: {is_k, eight_bit} <= {1'b1, 8'h00};
        endcase

endmodule
