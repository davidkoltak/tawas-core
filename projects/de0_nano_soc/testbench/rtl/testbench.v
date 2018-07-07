//
// Testbench
//
// by
//   David M. Koltak  05/30/2017
//
// The MIT License (MIT)
//
// Copyright (c) 2017 David M. Koltak
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

module testbench();

    reg sim_rst;
    reg sim_clk;
    reg sim_clk_gen;
    integer cycle_count;

    initial
    begin
        sim_rst = 1;
        sim_clk_gen = 0;
        $dumpfile("results.vcd");
        $dumpvars(0);
        cycle_count = 0;
        #10 sim_rst = 0;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #5 sim_rst = 1;
        #5 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen;
        #10 sim_clk_gen = ~sim_clk_gen; sim_rst = 0;
        while (1)
        begin
            #10 sim_clk_gen = ~sim_clk_gen;
            cycle_count = (sim_clk_gen) ? cycle_count : cycle_count + 1;
        end
    end

    always @ (sim_clk_gen)
        sim_clk <= sim_clk_gen;

    integer CLOCK_LIMIT;
    wire [4:0] user_leds;
    reg [31:0] test_progress;

    always @ (posedge sim_clk or posedge sim_rst)
        if (sim_rst)
        begin
            CLOCK_LIMIT <= 32'd0;
            test_progress <= de0_nano_soc.testregs.test_progress;
        end
        else
        begin
            CLOCK_LIMIT <= CLOCK_LIMIT + 32'd1;
            if (CLOCK_LIMIT === `MAX_CLOCKS)
            begin
                #20;
                $display(" ****** MAX CLOCKS - ENDING SIMULATION *****");
                $finish();
            end

            if (de0_nano_soc.testregs.test_progress != test_progress)
            begin
                test_progress <= de0_nano_soc.testregs.test_progress;
                $display(" ****** TEST PROGRESS %X *****",
                de0_nano_soc.testregs.test_progress);
            end

            if (de0_nano_soc.testregs.test_fail != 32'd0)
            begin
                #20;
                $display(" ****** TEST FAILED  %08X *****" ,
                de0_nano_soc.testregs.test_fail);
                $finish();
            end

            if (de0_nano_soc.testregs.test_pass != 32'd0)
            begin
                #20;
                $display(" ****** TEST PASSED  %08X *****" ,
                de0_nano_soc.testregs.test_pass);
                $finish();
            end
        end

    reg sim_clk_slow;
    reg sim_clk_slow_gen;

    initial
    begin
        sim_clk_slow_gen = 0;
        while (1)
        begin
            #33 sim_clk_slow_gen = ~sim_clk_slow_gen;
        end
    end

    always @ (sim_clk_slow_gen)
        sim_clk_slow <= sim_clk_slow_gen;

    wire uart_tx;
    wire uart_rx;

    de0_nano_soc de0_nano_soc
    (
        .FPGA_CLK1_50(sim_clk),
        .FPGA_CLK2_50(sim_clk_slow),
        .FPGA_CLK3_50(~sim_clk),
        
        .BUTTON({1'b1, !sim_rst}),
        .SW(4'd0),
        .LED(),
        
        .UART_TX(uart_tx),
        .UART_RX(uart_rx),
        
        .SPDR_TX(uart_rx),
        .SPDR_RX(uart_tx)
    );

endmodule
