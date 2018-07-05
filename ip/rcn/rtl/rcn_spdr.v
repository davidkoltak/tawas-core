/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// RCN bus Serial Port DebuggeR (SPDR - pronounced "spider")
//
// Commands -
//    @addr : Set bus address
//    #size : Set bus size (b, h, or w)
//    =data : Write data at address (and inc by size)
//    ?     : Read data from address (and inc by size)
//    %data : Write GPO
//    /     : Read GPI
//    !     : Read the current bus address
//
// All values are in hex and are padded with zero to proper size. Providing
// too many hex digits is ignored as bytes are captured and shifted.
//
// The SPDR modules echoes valid entries and prints CrLf after each command.
// User terminals should select the remote echo option.
//

module rcn_spdr
(
    input clk,
    input clk_50,
    input rst,

    input [68:0] rcn_in,
    output [68:0] rcn_out,

    input [31:0] gpi,
    output reg gpi_strobe,
    output reg [31:0] gpo,
    output reg gpo_strobe,

    output uart_tx,
    input uart_rx
);
    parameter MASTER_ID = 0;
    parameter SAMPLE_CLK_DIV = 6'd61; // Value for 115200 @ 50 MHz in

    reg cs;
    wire busy;
    reg wr;
    reg [3:0] mask;
    reg [31:0] addr;
    reg [31:0] wdata;

    wire rdone;
    wire wdone;
    wire [31:0] rsp_data;

    rcn_master #(.MASTER_ID(MASTER_ID)) rcn_master
    (
        .rst(rst),
        .clk(clk),

        .rcn_in(rcn_in),
        .rcn_out(rcn_out),

        .cs(cs),
        .seq(2'b00),
        .busy(busy),
        .wr(wr),
        .mask(mask),
        .addr(addr[23:0]),
        .wdata(wdata),

        .rdone(rdone),
        .wdone(wdone),
        .rsp_seq(),
        .rsp_mask(),
        .rsp_addr(),
        .rsp_data(rsp_data)
    );

    wire tx_busy;
    wire tx_vld;
    wire [7:0] tx_data;

    wire rx_vld;
    wire [7:0] rx_data;

    rcn_uart_framer #(.SAMPLE_CLK_DIV(SAMPLE_CLK_DIV)) rcn_uart_framer
    (
        .clk_50(clk_50),
        .rst(rst),

        .tx_busy(tx_busy),
        .tx_vld(tx_vld),
        .tx_data(tx_data),

        .rx_vld(rx_vld),
        .rx_data(rx_data),
        .rx_frame_error(),

        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

    reg [7:0] tx_byte;
    reg tx_push;
    wire tx_full;
    wire tx_empty;

    assign tx_vld = !tx_empty;

    rcn_fifo_byte_async tx_fifo
    (
        .rst_in(rst),
        .clk_in(clk),
        .clk_out(clk_50),

        .din(tx_byte),
        .push(tx_push),
        .full(tx_full),

        .dout(tx_data),
        .pop(!tx_busy),
        .empty(tx_empty)
    );

    wire [7:0] rx_byte;
    reg rx_pop;
    wire rx_empty;

    rcn_fifo_byte_async rx_fifo
    (
        .rst_in(rst),
        .clk_in(clk_50),
        .clk_out(clk),

        .din(rx_data),
        .push(rx_vld),
        .full(),

        .dout(rx_byte),
        .pop(rx_pop),
        .empty(rx_empty)
    );

    reg rx_is_num;
    reg [3:0] rx_number;
    reg [31:0] rx_number_shift;

    always @ *
    begin
        rx_is_num = 1'b1;
        rx_number = 4'd0;
        case (rx_byte)
        '0': rx_number = 4'd0;
        '1': rx_number = 4'd1;
        '2': rx_number = 4'd2;
        '3': rx_number = 4'd3;
        '4': rx_number = 4'd4;
        '5': rx_number = 4'd5;
        '6': rx_number = 4'd6;
        '7': rx_number = 4'd7;
        '8': rx_number = 4'd8;
        '9': rx_number = 4'd9;
        'A': rx_number = 4'dA;
        'B': rx_number = 4'dB;
        'C': rx_number = 4'dC;
        'D': rx_number = 4'dD;
        'E': rx_number = 4'dE;
        'F': rx_number = 4'dF;
        'a': rx_number = 4'dA;
        'b': rx_number = 4'dB;
        'c': rx_number = 4'dC;
        'd': rx_number = 4'dD;
        'e': rx_number = 4'dE;
        'f': rx_number = 4'dF;
        default: rx_is_num = 1'b0;
        endcase
    end

    always @ (posedge clk)
        if (rx_pop && !rx_is_num)
            rx_number_shift <= 32'd0;
        else if (rx_pop)
            rx_number_shift <= {rx_number_shift[27:0], rx_number};

    reg update_addr;
    reg inc_addr;
    reg update_size;
    reg [2:0] size;

    always @ (posedge clk or posedge rst)
        if (rst)
            addr <= 32'd0;
        else if (update_addr)
            addr <= rx_number_shift;
        else if (inc_addr)
            addr <= addr + {29'd0, size};

    always @ (posedge clk or posedge rst)
        if (rst)
            size <= 3'd4;
        else if (update_size)
            case (rx_byte)
            'b': size <= 3'd1;
            'h': size <= 3'd2;
            'w': size <= 3'd4;
            default: size <= 3'd0;
            endcase;

    reg update_wdata;

    always @ (posedge clk or posedge rst)
        if (rst)
            wdata <= 32'd0;
        else (update_wdata)
            wdata <= rx_number_shift;

    reg update_gpo;

    always @ (posedge clk or posedge rst)
        if (rst)
            gpo <= 32'd0;
        else (update_gpo)
            gpo <= rx_number_shift;

    always @ (posedge clk)
        gpo_stobe <= update_gpo;

    reg capture_rdata;
    reg capture_gpi;
    reg capture_addr;
    reg capture_shift;
    reg [31:0] capture_data;
    reg [7:0] capture_byte;

    always @ (posedge clk or posedge rst)
        if (rst)
            capture_data <= 32'd0;
        else if (capture_rdata)
            capture_data <= rdata;
        else if (capture_gpi)
            capture_data <= gpi;
        else if (capture_addr)
            capture_data <= addr;
        else if (capture_shift)
            capture_data <= {capture_data[27:0], 4'd0};

    always @ (posedge clk)
        gpi_stobe <= capture_gpi;

    always @ *
        case (capture_data[31:28])
        4'h0: capture_byte = '0';
        4'h1: capture_byte = '1';
        4'h2: capture_byte = '2';
        4'h3: capture_byte = '3';
        4'h4: capture_byte = '4';
        4'h5: capture_byte = '5';
        4'h6: capture_byte = '6';
        4'h7: capture_byte = '7';
        4'h8: capture_byte = '8';
        4'h9: capture_byte = '9';
        4'hA: capture_byte = 'A';
        4'hB: capture_byte = 'B';
        4'hC: capture_byte = 'C';
        4'hD: capture_byte = 'D';
        4'hE: capture_byte = 'E';
        default: capture_byte = 'F';
        endcase

    reg [4:0] state;
    reg [4:0] next_state;

    always @ (posedge clk or posedge rst)
        if (rst)
            state <= 5'd0;
        else
            state <= next_state;

    always @ *
    begin
        next_state = state;
        cs = 1'b0;
        wr = 1'b0;
        rx_pop = 1'b0;
        tx_byte = 8'd0;
        tx_push = 1'b0;

        update_addr = 1'b0;
        inc_addr = 1'b0;
        update_size = 1'b0;
        update_data = 1'b0;
        update_gpo = 1'b0;
        capture_rdata = 1'b0;
        capture_gpi = 1'b0;
        capture_addr = 1'b0;
        capture_shift = 1'b0;

        case (state)
        5'd0:
            if (!rx_empty)
            begin
                rx_pop = 1''b1;
                tx_byte = rx_byte;
                tx_push = 1'b1;
                case (rx_byte)
                '@': next_state = 5'd1;
                '#': next_state = 5'd2;
                '=': next_state = 5'd3;
                '?': next_state = 5'd6;
                '%': next_state = 5'd8;
                '/': next_state = 5'd9:
                '!': next_state = 5'd10;
                default: tx_push = 1'b0;
                endcase
            end

        //
        // Update addr
        //

        5'd1:
            if (!rx_empty)
            begin
                rx_pop = 1''b1;
                tx_byte = rx_byte;
                tx_push = 1'b1;

                if (!rx_is_num)
                begin
                    tx_push = 1'b0;
                    update_addr = 1'b1;
                    next_state = 5'd30;
                end
            end

        //
        // Update size
        //

        5'd2:
            if (!rx_empty)
            begin
                rx_pop = 1''b1;
                tx_byte = rx_byte;
                tx_push = 1'b1;
                update_size = 1'b1;
                next_state = 5'd30;
            end

        //
        // Write data
        //

        5'd3:
            if (!rx_empty)
            begin
                rx_pop = 1''b1;
                tx_byte = rx_byte;
                tx_push = 1'b1;

                if (!rx_is_num)
                begin
                    tx_push = 1'b0;
                    update_wdata = 1'b1;
                    next_state = state + 5'd1;
                end
            end
        5'd4:
        begin
            cs = 1'b1;
            wr = 1'b1;
            if (!busy)
                next_state = state + 5'd1;
        end
        5'd5:
            if (wdone)
            begin
                inc_addr = 1'b1;
                next_state = 5'd30;
            end

        //
        // Read data
        //

        5'd6:
        begin
            cs = 1'b1;
            wr = 1'b0;
            if (!busy)
                next_state = state + 5'd1;
        end
        5'd7:
            if (rdone)
            begin
                inc_addr = 1'b1;
                capture_rdata = 1'b1;
                next_state = 5'd22;
            end

        //
        // Write gpo
        //

        5'd8:
            if (!rx_empty)
            begin
                rx_pop = 1''b1;
                tx_byte = rx_byte;
                tx_push = 1'b1;

                if (!rx_is_num)
                begin
                    tx_push = 1'b0;
                    update_gpo = 1'b1;
                    next_state = 5'd30;
                end
            end

        //
        // Read gpi
        //

        5'd9:
        begin
            capture_gpi = 1'b1;
            next_state = 5'd22;
        end

        //
        // Read address
        //

        5'd10:
        begin
            capture_addr = 1'b1;
            next_state = 5'd22;
        end

        //
        // Send capture register
        //

        5'd22:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd23:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd24:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd25:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd26:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd27:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd28:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd29:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        //
        // Send Cr/Lf and start over
        //

        5'd30:
            if (!tx_full)
            begin
                tx_byte = '\r';
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd31:
            if (!tx_full)
            begin
                tx_byte = '\r';
                tx_push = 1'b1;
                next_state = 5'd0;
            end

        default: next_state = 5'd0;
        endcase
    end

    always @ *
        if (size == 3'b001) // byte
            case (addr[1:0])
            2'b00: mask = 4'b0001;
            2'b01: mask = 4'b0010;
            2'b10: mask = 4'b0100;
            default: mask = 4'b1000;
            endcase
        else if (size == 3'b010) // half
            if (!addr[1])
                mask = 4'b0011;
            else
                mask = 4'b1100;
        else
            mask = 4'b1111;

endmodule
