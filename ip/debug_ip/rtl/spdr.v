/* SPDX-License-Identifier: MIT */
/* (c) Copyright 2018 David M. Koltak, all rights reserved. */

//
// Serial Port DebuggeR (SPDR - pronounced "spider")
//
// Commands -
//    @addr : Set bus address
//    #size : Set bus size (b, h, or w)
//    =data : Write data at address (and inc by size)
//    ?     : Read data from address (and inc by size)
//    %data : Write GPO
//    /     : Read GPI
//    !     : Read the current bus address/size
//
// All values are in hex and are padded with zero to proper size. Providing
// too many hex digits is ignored as bytes are captured and shifted. A backspace
// aborts commands with arguments (@,#,=,%).
//
// The SPDR modules echoes valid entries and prints CrLf after each command.
// User terminals should select the remote echo option.
//

module spdr
(
    input clk,
    input clk_50,
    input rst,

    input avm_waitrequest,
    input [31:0] avm_readdata,
    input avm_readdatavalid,
    input [1:0] avm_response,
    input avm_writeresponsevalid,
    output avm_burstcount,
    output [31:0] avm_writedata,
    output [31:0] avm_address,
    output avm_write,
    output avm_read,
    output [3:0] avm_byteenable,

    input [31:0] gpi,
    output reg gpi_strobe,
    output reg [31:0] gpo,
    output reg gpo_strobe,

    output uart_tx,
    input uart_rx
);
    parameter SAMPLE_CLK_DIV = 6'd62; // Value for 115200 @ 50 MHz in

    //
    // Avalon MM bus signals
    //
    
    reg cs;
    wire busy;
    reg wr;
    reg [3:0] mask;
    reg [31:0] addr;
    reg [31:0] wdata_final;

    wire rdone;
    wire wdone;
    wire [31:0] rsp_data;
    wire rsp_is_err = (avm_response != 2'b00);

    assign busy = avm_waitrequest;
    assign avm_address = addr;
    assign avm_read = cs && !wr;
    assign avm_write = cs && wr;
    assign avm_byteenable = mask;
    assign avm_writedata = wdata_final;
    assign avm_burstcount = 1'b1;

    assign rdone = avm_readdatavalid;
    assign rsp_data = avm_readdata;
    assign wdone = avm_writeresponsevalid;

    //
    // UART Framer
    //

    wire tx_busy;
    wire tx_vld;
    wire [7:0] tx_data;

    wire rx_vld;
    wire [7:0] rx_data;

    spdr_uart_framer #(.SAMPLE_CLK_DIV(SAMPLE_CLK_DIV)) uart_framer
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

    spdr_fifo tx_fifo
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

    spdr_fifo rx_fifo
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
    reg rx_is_backspace;
    reg [3:0] rx_number;
    reg [31:0] rx_number_shift;

    always @ *
    begin
        rx_is_num = 1'b1;
        rx_is_backspace = 1'b0;
        rx_number = 4'd0;
        case (rx_byte)
        "0": rx_number = 4'h0;
        "1": rx_number = 4'h1;
        "2": rx_number = 4'h2;
        "3": rx_number = 4'h3;
        "4": rx_number = 4'h4;
        "5": rx_number = 4'h5;
        "6": rx_number = 4'h6;
        "7": rx_number = 4'h7;
        "8": rx_number = 4'h8;
        "9": rx_number = 4'h9;
        "A": rx_number = 4'hA;
        "B": rx_number = 4'hB;
        "C": rx_number = 4'hC;
        "D": rx_number = 4'hD;
        "E": rx_number = 4'hE;
        "F": rx_number = 4'hF;
        "a": rx_number = 4'hA;
        "b": rx_number = 4'hB;
        "c": rx_number = 4'hC;
        "d": rx_number = 4'hD;
        "e": rx_number = 4'hE;
        "f": rx_number = 4'hF;
        8'h08:
        begin
            rx_is_num = 1'b0;
            rx_is_backspace = 1'b1;
        end
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
    reg [1:0] size_mode;
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
            size_mode <= 2'd0;
        else if (update_size)
            case (rx_byte)
            "b": size_mode <= 2'd2;
            "h": size_mode <= 2'd1;
            "w": size_mode <= 2'd0;
            default: size_mode <= 2'd0;
            endcase

    reg update_wdata;
    reg [31:0] wdata;

    always @ (posedge clk or posedge rst)
        if (rst)
            wdata <= 32'd0;
        else if (update_wdata)
            wdata <= rx_number_shift;

    reg update_gpo;

    always @ (posedge clk or posedge rst)
        if (rst)
            gpo <= 32'd0;
        else if (update_gpo)
            gpo <= rx_number_shift;

    always @ (posedge clk)
        gpo_strobe <= update_gpo;

    reg [31:0] rdata_final;
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
            capture_data <= rdata_final;
        else if (capture_gpi)
            capture_data <= gpi;
        else if (capture_addr)
            capture_data <= addr;
        else if (capture_shift)
            capture_data <= {capture_data[27:0], 4'd0};

    always @ (posedge clk)
        gpi_strobe <= capture_gpi;

    always @ *
        case (capture_data[31:28])
        4'h0: capture_byte = "0";
        4'h1: capture_byte = "1";
        4'h2: capture_byte = "2";
        4'h3: capture_byte = "3";
        4'h4: capture_byte = "4";
        4'h5: capture_byte = "5";
        4'h6: capture_byte = "6";
        4'h7: capture_byte = "7";
        4'h8: capture_byte = "8";
        4'h9: capture_byte = "9";
        4'hA: capture_byte = "A";
        4'hB: capture_byte = "B";
        4'hC: capture_byte = "C";
        4'hD: capture_byte = "D";
        4'hE: capture_byte = "E";
        default: capture_byte = "F";
        endcase

    reg [15:0] bus_timer;
    reg bus_timer_rst;
    wire bus_timeout = (bus_timer[15:4] == 12'hFFF);
    
    always @ (posedge clk)
        if (bus_timer_rst)
            bus_timer <= 16'd0;
        else if (~bus_timeout)
            bus_timer <= bus_timer + 16'd1;

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
        bus_timer_rst = 1'b0;
        rx_pop = 1'b0;
        tx_byte = 8'd0;
        tx_push = 1'b0;

        update_addr = 1'b0;
        inc_addr = 1'b0;
        update_size = 1'b0;
        update_wdata = 1'b0;
        update_gpo = 1'b0;
        capture_rdata = 1'b0;
        capture_gpi = 1'b0;
        capture_addr = 1'b0;
        capture_shift = 1'b0;

        case (state)
        5'd0:
            if (!rx_empty)
            begin
                rx_pop = 1'b1;
                tx_byte = rx_byte;
                tx_push = 1'b1;
                case (rx_byte)
                "@": next_state = 5'd1;
                "#": next_state = 5'd2;
                "=": next_state = 5'd3;
                "?": next_state = 5'd6;
                "%": next_state = 5'd8;
                "/": next_state = 5'd9;
                "!": next_state = 5'd10;
                default: tx_push = 1'b0;
                endcase
            end

        //
        // Update addr
        //

        5'd1:
            if (!rx_empty)
            begin
                rx_pop = 1'b1;
                tx_byte = rx_byte;
                tx_push = 1'b1;

                if (!rx_is_num)
                begin
                    tx_push = 1'b0;
                    update_addr = !rx_is_backspace;
                    next_state = 5'd30;
                end
            end

        //
        // Update size
        //

        5'd2:
            if (!rx_empty)
            begin
                rx_pop = 1'b1;
                tx_byte = rx_byte;
                tx_push = 1'b1;
                update_size = !rx_is_backspace;
                next_state = 5'd30;
            end

        //
        // Write data
        //

        5'd3:
            if (!rx_empty)
            begin
                rx_pop = 1'b1;
                tx_byte = rx_byte;
                tx_push = 1'b1;

                if (!rx_is_num)
                begin
                    tx_push = 1'b0;
                    update_wdata = 1'b1;
                    next_state = (rx_is_backspace) ? 5'd30 : state + 5'd1;
                end
            end
        5'd4:
        begin
            cs = 1'b1;
            wr = 1'b1;
            bus_timer_rst = 1'b1;
            if (!busy)
                next_state = state + 5'd1;
        end
        5'd5:
            if (wdone)
            begin
                if (rsp_is_err)
                    next_state = 5'd12;
                else
                begin
                    inc_addr = 1'b1;
                    next_state = 5'd30;
                end
            end
            else if (bus_timeout)
                next_state = 5'd12;

        //
        // Read data
        //

        5'd6:
        begin
            cs = 1'b1;
            wr = 1'b0;
            bus_timer_rst = 1'b1;
            if (!busy)
                next_state = state + 5'd1;
        end
        5'd7:
            if (rdone)
            begin
                if (rsp_is_err)
                    next_state = 5'd12;
                else
                begin
                    inc_addr = 1'b1;
                    capture_rdata = 1'b1;
                    next_state = 5'd16;
                end
            end
            else if (bus_timeout)
                next_state = 5'd12;

        //
        // Write gpo
        //

        5'd8:
            if (!rx_empty)
            begin
                rx_pop = 1'b1;
                tx_byte = rx_byte;
                tx_push = 1'b1;

                if (!rx_is_num)
                begin
                    tx_push = 1'b0;
                    update_gpo = !rx_is_backspace;
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
        // Read address/size
        //

        5'd10:
            if (!tx_full)
            begin
                case (size_mode)
                2'd0: tx_byte = "w";
                2'd1: tx_byte = "h";
                default: tx_byte = "b";
                endcase
                
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd11:
            if (!tx_full)
            begin
                tx_byte = "-";
                tx_push = 1'b1;
                capture_addr = 1'b1;
                next_state = 5'd22;
            end

        //
        // Send Error Indicator
        //
        
        5'd12:
            if (!tx_full)
            begin
                tx_byte = ":";
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end
            
        5'd13:
            if (!tx_full)
            begin
                tx_byte = "E";
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd14:
            if (!tx_full)
            begin
                tx_byte = "r";
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd15:
            if (!tx_full)
            begin
                tx_byte = "r";
                tx_push = 1'b1;
                next_state = 5'd30;
            end
        
        //
        // Send capture based on size
        //

        5'd16:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = size[2];
                next_state = state + 5'd1;
            end

        5'd17:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = size[2];
                next_state = state + 5'd1;
            end

        5'd18:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = size[2];
                next_state = state + 5'd1;
            end

        5'd19:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = size[2];
                next_state = state + 5'd1;
            end

        5'd20:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = |size[2:1];
                next_state = state + 5'd1;
            end

        5'd21:
            if (!tx_full)
            begin
                capture_shift = 1'b1;
                tx_byte = capture_byte;
                tx_push = |size[2:1];
                next_state = 5'd28;
            end

        //
        // Send all of capture data register
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
                tx_byte = 8'h0D;
                tx_push = 1'b1;
                next_state = state + 5'd1;
            end

        5'd31:
            if (!tx_full)
            begin
                tx_byte = 8'h0A;
                tx_push = 1'b1;
                next_state = 5'd0;
            end

        default: next_state = 5'd0;
        endcase
    end

    always @ *
        if (size_mode == 2'd0) // word
        begin
            size = 3'b100;
            mask = 4'b1111;
            wdata_final = wdata;
            rdata_final = rsp_data;
        end
        else if (size_mode == 2'd1) // half
        begin
            size = 3'b010;
            wdata_final = {2{wdata[15:0]}};
            if (!addr[1])
            begin
                mask = 4'b0011;
                   rdata_final = {16'd0, rsp_data[15:0]};
            end
            else
            begin
                mask = 4'b1100;
                rdata_final = {16'd0, rsp_data[31:16]};
            end
        end
        else
        begin
            size = 3'b001;
            wdata_final = {4{wdata[7:0]}};
            case (addr[1:0])
            2'b00:
            begin
                mask = 4'b0001;
                rdata_final = {24'd0, rsp_data[7:0]};
            end
            2'b01:
            begin
                mask = 4'b0010;
                rdata_final = {24'd0, rsp_data[15:8]};
            end
            2'b10:
            begin
                mask = 4'b0100;
                rdata_final = {24'd0, rsp_data[23:16]};
            end
            default:
            begin
                mask = 4'b1000;
                rdata_final = {24'd0, rsp_data[31:24]};
            end
            endcase
        end

endmodule
