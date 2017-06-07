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
  
  always @ (posedge sim_clk or posedge sim_rst)
    if (sim_rst)
      CLOCK_LIMIT <= 32'd0;
    else
    begin
      CLOCK_LIMIT <= CLOCK_LIMIT + 32'd1;
      if (CLOCK_LIMIT === `MAX_CLOCKS)
      begin
        #20;
        $display(" ****** MAX CLOCKS - ENDING SIMULATION *****");
        $finish();
      end
      if (max10_devkit_top.tawas.raccoon_cs && max10_devkit_top.tawas.dwr_out)
         if (max10_devkit_top.tawas.daddr_out[31:0] == 32'hFFFFFFF0)
        begin
          $display(" ****** TEST STATUS %X - ENDING SIMULATION *****", 
                   max10_devkit_top.tawas.dout_out[31:0]);
        end
        else if (max10_devkit_top.tawas.daddr_out[31:0] == 32'hFFFFFFF8)
        begin
          #20;
          $display(" ****** TEST FAILED - ENDING SIMULATION *****");
          $finish();
        end
        else if (max10_devkit_top.tawas.daddr_out[31:0] == 32'hFFFFFFFC)
        begin
          #20;
          $display(" ****** TEST PASSED - ENDING SIMULATION *****");
          $finish();
        end
    end
  
  max10_devkit_top max10_devkit_top
  (
    .clk_50(sim_clk),
    .fpga_reset_n(!sim_rst),

    .qspi_clk(),
    .qspi_io(),
    .qspi_csn(),

    .uart_rx(1'b1),
    .uart_tx(),

    .user_led(user_leds),
    .user_pb(4'b1111)
  );
  
endmodule
