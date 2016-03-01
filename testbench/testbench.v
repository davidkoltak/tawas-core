
module testbench();

  reg sim_rst;
  reg sim_clk;
  reg sim_clk_gen;
  
  initial
  begin
    sim_rst = 1;
    sim_clk_gen = 0;
    $dumpfile("results.vcd");
    $dumpvars(0);
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
    while (1) #10 sim_clk_gen = ~sim_clk_gen;
  end
  
  always @ (sim_clk_gen)
    sim_clk <= sim_clk_gen;
  
  integer CLOCK_LIMIT;
  
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
    end
    
  wire [23:0] irom_addr;
  wire [31:0] irom_data;
  
  irom irom
  (
    .CLK(sim_clk),

    .ADDR(irom_addr),
    .CS(1'b1),
    .DOUT(irom_data)
  );

  wire [31:0] dram_addr;
  wire dram_cs;
  wire dram_wr;
  wire [3:0] dram_mask;
  wire [31:0] dram_din;
  wire [31:0] dram_dout;
  
  always @ (posedge sim_clk)
    if (dram_cs && dram_wr)
    begin
      case (dram_addr)
      32'hFFFFFFF0:
      begin
        $display("### SIMULATION INFO - 0x%08X ###", dram_din);
      end
      32'hFFFFFFF4:
      begin
        $display("### SIMULATION WARN - 0x%08X ###", dram_din);
      end
      32'hFFFFFFF8:
      begin
        $display("### SIMULATION PASSED - 0x%08X ###", dram_din);
        @(posedge sim_clk);
        @(posedge sim_clk);
        @(posedge sim_clk);
        @(posedge sim_clk);
        $finish();
      end
      32'hFFFFFFFC:
      begin
        $display("### SIMULATION FAILED - 0x%08X ###", dram_din);
        @(posedge sim_clk);
        @(posedge sim_clk);
        @(posedge sim_clk);
        @(posedge sim_clk);
        $finish();
      end
      default: ;
      endcase
    end
    
  dram dram
  (
    .CLK(sim_clk),

    .ADDR(dram_addr),
    .CS(dram_cs),
    .WR(dram_wr),
    .MASK(dram_mask),
    .DIN(dram_din),
    .DOUT(dram_dout)
  );

  tawas tawas
  (
    .CLK(sim_clk),
    .RST(sim_rst),

    .IADDR(irom_addr),
    .IDATA(irom_data),

    .DADDR(dram_addr),
    .DCS(dram_cs),
    .DWR(dram_wr),
    .DMASK(dram_mask),
    .DOUT(dram_din),
    .DIN(dram_dout)
  );
  
endmodule
