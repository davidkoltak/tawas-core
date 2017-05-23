
module racc_subsys
(
  input CLK,
  input RST,
  
  input [79:0] RaccIn,
  output [79:0] RaccOut
);

  wire [79:0] racc_in_event;
  wire [79:0] racc_out_event;
  wire [79:0] racc_out_ram;
  wire [79:0] racc_out_ram_w;
  wire [79:0] racc_out_reg;

  raccoon_delay #(.DELAY_CYCLES(1)) raccoon_delay_in
  (
    .CLK(CLK),
    .RST(RST),

    .RaccIn(RaccIn),
    .RaccOut(racc_in_event)
  );

  raccoon_delay #(.DELAY_CYCLES(1)) raccoon_delay_out
  (
    .CLK(CLK),
    .RST(RST),

    .RaccIn(racc_out_reg),
    .RaccOut(RaccOut)
  );
  
  raccoon_event #(.ADDR_MASK(32'hFFFFFFF0), .ADDR_BASE(32'hFFFFFFE0)) raccoon_event
  (
    .CLK(CLK),
    .RST(RST),

    .RaccIn(racc_in_event),
    .RaccOut(racc_out_event)
  );

  wire racc_ram_cs;
  wire racc_ram_we;
  wire [31:0] racc_ram_addr;
  wire [3:0] racc_ram_mask;
  wire [31:0] racc_ram_wdata;
  wire [31:0] racc_ram_rdata;
  
  raccoon2ram #(.ADDR_MASK(32'hFFFF0000), .ADDR_BASE(32'hE0000000)) raccoon2ram
  (
    .CLK(CLK),
    .RST(RST),

    .RaccIn(racc_out_event),
    .RaccOut(racc_out_ram),

    .CS(racc_ram_cs),
    .WE(racc_ram_we),
    .ADDR(racc_ram_addr),
    .MASK(racc_ram_mask),
    .WR_DATA(racc_ram_wdata),
    .RD_DATA(racc_ram_rdata)
  );

  racc_ram racc_ram
  (
    .CLK(CLK),

    .ADDR(racc_ram_addr),
    .CS(racc_ram_cs),
    .WR(racc_ram_we),
    .MASK(racc_ram_mask),
    .DIN(racc_ram_wdata),
    .DOUT(racc_ram_rdata)
  );

  wire racc_ram_w_cs;
  reg [6:0] racc_ram_w_wait;
  wire racc_ram_w_we;
  wire [31:0] racc_ram_w_addr;
  wire [3:0] racc_ram_w_mask;
  wire [31:0] racc_ram_w_wdata;
  wire [31:0] racc_ram_w_rdata;
  
  raccoon2ram_w #(.ADDR_MASK(32'hFFFF0000), .ADDR_BASE(32'hE0010000)) raccoon2ram_w
  (
    .CLK(CLK),
    .RST(RST),

    .RaccIn(racc_out_ram),
    .RaccOut(racc_out_ram_w),

    .CS(racc_ram_w_cs),
    .WAIT(racc_ram_w_wait[0]),
    .WE(racc_ram_w_we),
    .ADDR(racc_ram_w_addr),
    .MASK(racc_ram_w_mask),
    .WR_DATA(racc_ram_w_wdata),
    .RD_DATA(racc_ram_w_rdata)
  );
  
  always @ (posedge CLK)
    if (!racc_ram_w_cs)
      racc_ram_w_wait <= {7{1'b1}};
    else
      racc_ram_w_wait <= {1'b0, racc_ram_w_wait[6:1]};

  racc_ram racc_ram_w
  (
    .CLK(CLK),

    .ADDR(racc_ram_w_addr),
    .CS(racc_ram_w_cs),
    .WR(racc_ram_w_we),
    .MASK(racc_ram_w_mask),
    .DIN(racc_ram_w_wdata),
    .DOUT(racc_ram_w_rdata)
  );

  wire racc_reg_cs;
  wire racc_reg_we;
  wire [31:0] racc_reg_addr;
  wire [3:0] racc_reg_mask;
  wire [31:0] racc_reg_wdata;
  wire [31:0] racc_reg_rdata = 32'd0;
  
  raccoon2ram #(.ADDR_MASK(32'hFFFFFFF0), .ADDR_BASE(32'hFFFFFFF0)) raccoon2reg
  (
    .CLK(CLK),
    .RST(RST),

    .RaccIn(racc_out_ram_w),
    .RaccOut(racc_out_reg),

    .CS(racc_reg_cs),
    .WE(racc_reg_we),
    .ADDR(racc_reg_addr),
    .MASK(racc_reg_mask),
    .WR_DATA(racc_reg_wdata),
    .RD_DATA(racc_reg_rdata)
  );

  always @ (posedge CLK)
    if (racc_reg_cs && racc_reg_we)
    begin
      case (racc_reg_addr[3:0])
      4'h0:
      begin
        $display("### SIMULATION INFO - 0x%08X ###", racc_reg_wdata[31:0]);
      end
      4'h4:
      begin
        $display("### SIMULATION WARN - 0x%08X ###", racc_reg_wdata[31:0]);
      end
      4'h8:
      begin
        $display("### SIMULATION PASSED - 0x%08X ###", racc_reg_wdata[31:0]);
        @(posedge CLK);
        @(posedge CLK);
        @(posedge CLK);
        @(posedge CLK);
        $finish();
      end
      4'hC:
      begin
        $display("### SIMULATION FAILED - 0x%08X ###", racc_reg_wdata[31:0]);
        @(posedge CLK);
        @(posedge CLK);
        @(posedge CLK);
        @(posedge CLK);
        $finish();
      end
      default: ;
      endcase
    end
        
endmodule
