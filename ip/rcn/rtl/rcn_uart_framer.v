/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// UART ser/des framer for use in RCN bus IP. Hard coded for 115200,1,1.
//

module rcn_uart_framer
(
    input clk_50,
    input rst,

    output reg tx_busy,
    input tx_vld,
    input [7:0] tx_data,

    output rx_vld,
    output [7:0] rx_data,
    output reg rx_frame_error,

    output uart_tx,
    input uart_rx
);
    parameter SAMPLE_CLK_DIV = 6'd62; // Value for 115200 @ 50 MHz in

    //
    // 50 MHz -> sample clock (7 * bit)
    //

    reg [5:0] sample_cnt;
    reg sample_en;

    always @ (posedge clk_50 or posedge rst)
        if (rst)
        begin
            sample_cnt <= 6'd0;
            sample_en <= 1'b0;
        end
        else if (sample_cnt == SAMPLE_CLK_DIV)
        begin
            sample_cnt <= 6'd0;
            sample_en <= 1'b1;
        end
        else
        begin
            sample_cnt <= sample_cnt + 6'd1;
            sample_en <= 1'b0;
        end

    //
    // Rx data sample state machine
    //

    reg [6:0] rx_sample;
    reg [2:0] rx_bitclk_cnt;
    reg rx_bitclk_en;
    reg [3:0] rx_bit_cnt;

    reg rx_busy;

    wire rx_falling_clean = (rx_sample[6:0] == 7'b1110000);
    wire rx_falling_dirty = (rx_sample[6:4] == 3'b110) && (rx_sample[1:0] == 2'b00);
    wire rx_falling = rx_falling_clean || rx_falling_dirty;

    wire rx_high = (rx_sample[2:1] == 2'b11);
    wire rx_low = (rx_sample[2:1] == 2'b00);

    always @ (posedge clk_50 or posedge rst)
        if (rst)
            rx_sample <= 7'd0;
        else if (sample_en)
            rx_sample <= {rx_sample[5:0], uart_rx};

    always @ (posedge clk_50 or posedge rst)
        if (rst)
        begin
            rx_bitclk_cnt <= 3'd0;
            rx_bitclk_en <= 1'b0;
            rx_bit_cnt <= 4'd0;
            rx_busy <= 1'b0;
        end
        else if (sample_en)
        begin
            if (!rx_busy)
            begin
                rx_bitclk_cnt <= 3'd0;
                rx_bitclk_en <= 1'b0;
                rx_bit_cnt <= 4'd0;
                rx_busy <= (rx_falling) ? 1'b1 : 1'b0;
            end
            else
            begin
                rx_busy <= (rx_bit_cnt == 4'd9) ? 1'b0 : 1'b1;

                rx_bitclk_en <= (rx_bitclk_cnt == 3'd5) ? 1'b1 : 1'b0;

                if (rx_bitclk_cnt == 3'd6)
                begin
                    rx_bitclk_cnt <= 3'd0;
                    rx_bit_cnt <= rx_bit_cnt + 4'd1;
                end
                else
                begin
                    rx_bitclk_cnt <= rx_bitclk_cnt + 3'd1;
                end
            end
        end

    //
    // Rx bit capture and signalling
    //

    reg [8:0] rx_capture;
    reg [8:0] rx_signal_errors;
    reg rx_data_done;
    reg rx_busy_d1;

    always @ (posedge clk_50 or posedge rst)
        if (rst)
        begin
            rx_capture <= 9'd0;
            rx_signal_errors <= 9'd0;
        end
        else if (sample_en && rx_bitclk_en)
        begin
            rx_capture <= {rx_high && !rx_low, rx_capture[8:1]};
            rx_signal_errors <= {!rx_high && !rx_low, rx_signal_errors[8:1]};
        end

    always @ (posedge clk_50 or posedge rst)
        if (rst)
        begin
            rx_data_done <= 1'b0;
            rx_busy_d1 <= 1'b0;
        end
        else
        begin
            rx_data_done <= rx_busy_d1 && !rx_busy;
            rx_busy_d1 <= rx_busy;
        end

    assign rx_vld = rx_data_done;
    assign rx_data = rx_capture[7:0];

    always @ (posedge clk_50)
        rx_frame_error <= (rx_signal_errors != 9'd0) || !rx_capture[8];

    //
    // Tx state machine
    //

    reg [8:0] tx_shift;
    reg [2:0] tx_bitclk_cnt;
    reg [3:0] tx_cnt;

    assign uart_tx = tx_shift[0];

    always @ (posedge clk_50 or posedge rst)
        if (rst)
        begin
            tx_shift <= {9{1'b1}};
            tx_bitclk_cnt <= 3'd0;
            tx_cnt <= 4'd0;
            tx_busy <= 1'b0;
        end
        else if (!tx_busy && tx_vld)
        begin
            tx_shift <= {tx_data, 1'b0};
            tx_bitclk_cnt <= 3'd0;
            tx_cnt <= 4'd0;
            tx_busy <= 1'b1;
        end
        else if (sample_en)
        begin
            tx_busy <= (tx_cnt == 4'd10) ? 1'b0 : 1'b1;

            if (tx_bitclk_cnt == 3'd6)
            begin
                tx_bitclk_cnt <= 3'd0;
                tx_shift <= {1'b1, tx_shift[8:1]};
                tx_cnt <= tx_cnt + 4'd1;
            end
            else
            begin
                tx_bitclk_cnt <= tx_bitclk_cnt + 3'd1;
            end
        end

endmodule
