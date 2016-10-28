
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
      32'h7FFFFFF0:
      begin
        $display("### SIMULATION INFO - 0x%08X ###", dram_din);
      end
      32'h7FFFFFF4:
      begin
        $display("### SIMULATION WARN - 0x%08X ###", dram_din);
      end
      32'h7FFFFFF8:
      begin
        $display("### SIMULATION PASSED - 0x%08X ###", dram_din);
        @(posedge sim_clk);
        @(posedge sim_clk);
        @(posedge sim_clk);
        @(posedge sim_clk);
        $finish();
      end
      32'h7FFFFFFC:
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

  wire [1:0] AWID;
  wire [31:0] AWADDR;
  wire [3:0] AWLEN;
  wire [2:0] AWSIZE;
  wire [1:0] AWBURST;
  wire [1:0] AWLOCK;
  wire [3:0] AWCACHE;
  wire [2:0] AWPROT;
  wire AWVALID;
  wire AWREADY;

  wire [1:0] WID;
  wire [63:0] WDATA;
  wire [7:0] WSTRB;
  wire WLAST;
  wire WVALID;
  wire WREADY;

  wire [1:0] BID;
  wire [1:0] BRESP;
  wire BVALID;
  wire BREADY;

  wire [1:0] ARID;
  wire [31:0] ARADDR;
  wire [3:0] ARLEN;
  wire [2:0] ARSIZE;
  wire [1:0] ARBURST;
  wire [1:0] ARLOCK;
  wire [3:0] ARCACHE;
  wire [2:0] ARPROT;
  wire ARVALID;
  wire ARREADY;

  wire [1:0] RID;
  wire [63:0] RDATA;
  wire [1:0] RRESP;
  wire RLAST;
  wire RVALID;
  wire RREADY;
  
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
    .DIN(dram_dout),
    
    .AWID(AWID),
    .AWADDR(AWADDR),
    .AWLEN(AWLEN),
    .AWSIZE(AWSIZE),
    .AWBURST(AWBURST),
    .AWLOCK(AWLOCK),
    .AWCACHE(AWCACHE),
    .AWPROT(AWPROT),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),

    .WID(WID),
    .WDATA(WDATA),
    .WSTRB(WSTRB),
    .WLAST(WLAST),
    .WVALID(WVALID),
    .WREADY(WREADY),

    .BID(BID),
    .BRESP(BRESP),
    .BVALID(BVALID),
    .BREADY(BREADY),

    .ARID(ARID),
    .ARADDR(ARADDR),
    .ARLEN(ARLEN),
    .ARSIZE(ARSIZE),
    .ARBURST(ARBURST),
    .ARLOCK(ARLOCK),
    .ARCACHE(ARCACHE),
    .ARPROT(ARPROT),
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),

    .RID(RID),
    .RDATA(RDATA),
    .RRESP(RRESP),
    .RLAST(RLAST),
    .RVALID(RVALID),
    .RREADY(RREADY)
  );

  wire [65:0] SpMBUS;
  wire SpMVLD;
  wire SpMRDY;
    
  wire [65:0] SpSBUS;
  wire SpSVLD;
  wire SpSRDY;
    
  axi2spartan #(.ID_WIDTH(2), .BWIDTH(64)) axi2spartan
  (
    .CLK(sim_clk),
    .RST(sim_rst),

    .AWID(AWID),
    .AWADDR(AWADDR),
    .AWLEN(AWLEN),
    .AWSIZE(AWSIZE),
    .AWBURST(AWBURST),
    .AWLOCK(AWLOCK),
    .AWCACHE(AWCACHE),
    .AWPROT(AWPROT),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),

    .WID(WID),
    .WDATA(WDATA),
    .WSTRB(WSTRB),
    .WLAST(WLAST),
    .WVALID(WVALID),
    .WREADY(WREADY),

    .BID(BID),
    .BRESP(BRESP),
    .BVALID(BVALID),
    .BREADY(BREADY),

    .ARID(ARID),
    .ARADDR(ARADDR),
    .ARLEN(ARLEN),
    .ARSIZE(ARSIZE),
    .ARBURST(ARBURST),
    .ARLOCK(ARLOCK),
    .ARCACHE(ARCACHE),
    .ARPROT(ARPROT),
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),

    .RID(RID),
    .RDATA(RDATA),
    .RRESP(RRESP),
    .RLAST(RLAST),
    .RVALID(RVALID),
    .RREADY(RREADY),

    .SpMBUS(SpMBUS),
    .SpMVLD(SpMVLD),
    .SpMRDY(SpMRDY),

    .SpSBUS(SpSBUS),
    .SpSVLD(SpSVLD),
    .SpSRDY(SpSRDY)
  );

  wire [31:0] axi_ram_addr;
  wire axi_ram_cs;
  wire axi_ram_wr;
  wire [63:0] axi_ram_mask;
  wire [63:0] axi_ram_din;
  wire [63:0] axi_ram_dout;
    
  spartan2ram #(.BWIDTH(64)) spartan2ram
  (
    .CLK(sim_clk),
    .RST(sim_rst),

    .SpMBUS(SpMBUS),
    .SpMVLD(SpMVLD),
    .SpMRDY(SpMRDY),

    .SpSBUS(SpSBUS),
    .SpSVLD(SpSVLD),
    .SpSRDY(SpSRDY),

    .CS(axi_ram_cs),
    .WE(axi_ram_wr),
    .ADDR(axi_ram_addr),
    .MASK(axi_ram_mask),
    .WR_DATA(axi_ram_din),
    .RD_DATA(axi_ram_dout)
  );

  axi_ram axi_ram
  (
    .CLK(sim_clk),

    .ADDR(axi_ram_addr),
    .CS(axi_ram_cs),
    .WR(axi_ram_wr),
    .MASK(axi_ram_mask),
    .DIN(axi_ram_din),
    .DOUT(axi_ram_dout)
  );
  
endmodule
