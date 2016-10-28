
//
// Tawas AXI bus interface:
//
// Perform load/store operations over AXI. Stall issueing thread while transaction is pending.
//
// by
//   David M. Koltak  10/28/2016
//
// The MIT License (MIT)
// 
// Copyright (c) 2016 David M. Koltak
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

module tawas_axi
(
  input CLK,
  input RST,

  input [1:0] SLICE,
  output reg [3:0] AXI_STALL,
  
  input [31:0] DADDR,
  input AXI_CS,
  input [2:0] AXI_RC,
  input DWR,
  input [3:0] DMASK,
  input [31:0] DOUT,
      
  output reg AXI_LOAD_VLD,
  output reg [1:0] AXI_LOAD_SLICE,
  output reg [2:0] AXI_LOAD_SEL,
  output reg [31:0] AXI_LOAD,
  
  output reg [1:0] AWID,
  output reg [31:0] AWADDR,
  output [3:0] AWLEN,
  output [2:0] AWSIZE,
  output [1:0] AWBURST,
  output [1:0] AWLOCK,
  output [3:0] AWCACHE,
  output [2:0] AWPROT,
  output reg AWVALID,
  input AWREADY,

  output reg [1:0] WID,
  output reg [63:0] WDATA,
  output reg [7:0] WSTRB,
  output WLAST,
  output reg WVALID,
  input WREADY,

  input [1:0] BID,
  input [1:0] BRESP,
  input BVALID,
  output BREADY,

  output reg [1:0] ARID,
  output reg [31:0] ARADDR,
  output [3:0] ARLEN,
  output [2:0] ARSIZE,
  output [1:0] ARBURST,
  output [1:0] ARLOCK,
  output [3:0] ARCACHE,
  output [2:0] ARPROT,
  output reg ARVALID,
  input ARREADY,

  input [1:0] RID,
  input [63:0] RDATA,
  input [1:0] RRESP,
  input RLAST,
  input RVALID,
  output RREADY
);

  //
  // Pending transactions... one per thread
  //
  
  reg [3:0] read_req;
  reg [3:0] read_ack;
  
  reg [3:0] write_req;
  reg [3:0] write_ack;
  
  reg [3:0] pending_read;
  reg [3:0] pending_write;
  
  assign BREADY = 1'b1;
  assign RREADY = 1'b1;
  
  always @ *
  begin
    if (AXI_CS & DWR)
      case (SLICE[1:0])
      2'd0: write_req = 4'b0100;
      2'd1: write_req = 4'b1000;
      2'd2: write_req = 4'b0001;
      default: write_req = 4'b0010;
      endcase
      
    if (AXI_CS & !DWR)
      case (SLICE[1:0])
      2'd0: read_req = 4'b0100;
      2'd1: read_req = 4'b1000;
      2'd2: read_req = 4'b0001;
      default: read_req = 4'b0010;
      endcase
    
    if (BVALID && (BRESP == 2'b00))
      case (BID[1:0])
      2'd0: write_ack = 4'b0001;
      2'd1: write_ack = 4'b0010;
      2'd2: write_ack = 4'b0100;
      default: write_ack = 4'b1000;
      endcase
      
    if (RVALID && RLAST && (RRESP == 2'b00))
      case (RID[1:0])
      2'd0: read_ack = 4'b0001;
      2'd1: read_ack = 4'b0010;
      2'd2: read_ack = 4'b0100;
      default: read_ack = 4'b1000;
      endcase
  end
  
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      AXI_STALL <= 4'd0;
      pending_write <= 4'd0;
      pending_read <= 4'd0;
    end
    else
    begin
      AXI_STALL <= pending_write | pending_read;
      pending_write <= (pending_write & ~write_ack) | write_req;
      pending_read <= (pending_read & ~read_ack) | read_req;
    end

  //
  // Transaction data
  //
  
  reg [31:0] addr_0;
  reg [31:0] addr_1;
  reg [31:0] addr_2;
  reg [31:0] addr_3;
  
  reg [3:0] mask_0;
  reg [3:0] mask_1;
  reg [3:0] mask_2;
  reg [3:0] mask_3;
  
  reg [31:0] dout_0;
  reg [31:0] dout_1;
  reg [31:0] dout_2;
  reg [31:0] dout_3;
  
  reg [2:0] rc_0;
  reg [2:0] rc_1;
  reg [2:0] rc_2;
  reg [2:0] rc_3;
  
  always @ (posedge CLK)
    if (read_req[0] || write_req[0])
    begin
      addr_0 <= DADDR;
      mask_0 <= DMASK;
      dout_0 <= DOUT;
      rc_0 <= AXI_RC;
    end

  always @ (posedge CLK)
    if (read_req[1] || write_req[1])
    begin
      addr_1 <= DADDR;
      mask_1 <= DMASK;
      dout_1 <= DOUT;
      rc_1 <= AXI_RC;
    end
    
  always @ (posedge CLK)
    if (read_req[2] || write_req[2])
    begin
      addr_2 <= DADDR;
      mask_2 <= DMASK;
      dout_2 <= DOUT;
      rc_2 <= AXI_RC;
    end
    
  always @ (posedge CLK)
    if (read_req[3] || write_req[3])
    begin
      addr_3 <= DADDR;
      mask_3 <= DMASK;
      dout_3 <= DOUT;
      rc_3 <= AXI_RC;
    end

  //
  // Arbitrate write requests and send out AXI bus
  //
  
  reg [3:0] write_state;
  reg [3:0] write_sent;
  
  assign [3:0] AWLEN = 4'd0;
  assign [2:0] AWSIZE = 3'd2;
  assign [1:0] AWBURST = 2'd0;
  assign [1:0] AWLOCK = 2'd0;
  assign [3:0] AWCACHE = 4'd0;
  assign [2:0] AWPROT = 3'd0;
  assign WLAST = 1'b1;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      write_sent <= 4'd0;
    else
    begin
      write_sent[0] <= (write_sent[0] | (write_state == 4'd2)) && !write_ack[0];
      write_sent[1] <= (write_sent[1] | (write_state == 4'd5)) && !write_ack[1];
      write_sent[2] <= (write_sent[2] | (write_state == 4'd8)) && !write_ack[2];
      write_sent[3] <= (write_sent[3] | (write_state == 4'd11)) && !write_ack[3];
    end
    
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      write_state <= 4'd0;
      AWVALID <= 1'b0;
      WVALID <= 1'b0;
    end
    else
    begin
      case (write_state[3:0])
      4'd0:
        if (write_sent[0] || !pending_write[0])
          write_state <= write_state + 4'd3;
        else
        begin
          write_state <= write_state + 4'd1;
          AWVALID <= 1'b1;
          AWID <= 2'd0;
          AWADDR <= addr_0;
        end       
      4'd1:
        if (AWREADY)
        begin
          write_state <= write_state + 4'd1;
          AWVALID <= 1'b0;
          WVALID <= 1'b1;
          WID <= 2'd0;
          WDATA <= {dout_0, dout_0};
          WSTRB <= (addr_0[2]) ? {dmask_0, 4'd0} : {4'd0, dmask_0};
        end
      4'd2:
        if (WREADY)
        begin
          write_state <= write_state + 4'd1;
          WVALID <= 1'b0;
        end

      4'd3:
        if (write_sent[1] || !pending_write[1])
          write_state <= write_state + 4'd3;
        else
        begin
          write_state <= write_state + 4'd1;
          AWVALID <= 1'b1;
          AWID <= 2'd1;
          AWADDR <= addr_1;
        end       
      4'd4:
        if (AWREADY)
        begin
          write_state <= write_state + 4'd1;
          AWVALID <= 1'b0;
          WVALID <= 1'b1;
          WID <= 2'd1;
          WDATA <= {dout_1, dout_1};
          WSTRB <= (addr_1[2]) ? {dmask_1, 4'd0} : {4'd0, dmask_1};
        end
      4'd5:
        if (WREADY)
        begin
          write_state <= write_state + 4'd1;
          WVALID <= 1'b0;
        end

      4'd6:
        if (write_sent[2] || !pending_write[2])
          write_state <= write_state + 4'd3;
        else
        begin
          write_state <= write_state + 4'd1;
          AWVALID <= 1'b1;
          AWID <= 2'd2;
          AWADDR <= addr_2;
        end       
      4'd7:
        if (AWREADY)
        begin
          write_state <= write_state + 4'd1;
          AWVALID <= 1'b0;
          WVALID <= 1'b1;
          WID <= 2'd2;
          WDATA <= {dout_2, dout_2};
          WSTRB <= (addr_2[2]) ? {dmask_2, 4'd0} : {4'd0, dmask_2};
        end
      4'd8:
        if (WREADY)
        begin
          write_state <= write_state + 4'd1;
          WVALID <= 1'b0;
        end

      4'd9:
        if (write_sent[3] || !pending_write[3])
          write_state <= write_state + 4'd3;
        else
        begin
          write_state <= write_state + 4'd1;
          AWVALID <= 1'b1;
          AWID <= 2'd3;
          AWADDR <= addr_3;
        end       
      4'd10:
        if (AWREADY)
        begin
          write_state <= write_state + 4'd1;
          AWVALID <= 1'b0;
          WVALID <= 1'b1;
          WID <= 2'd3;
          WDATA <= {dout_3, dout_3};
          WSTRB <= (addr_3[2]) ? {dmask_3, 4'd0} : {4'd0, dmask_3};
        end
      4'd11:
        if (WREADY)
        begin
          write_state <= write_state + 4'd1;
          WVALID <= 1'b0;
        end
                                        
      default: write_state <= 4'd0;
      endcase
      
    end
 
   //
  // Arbitrate read requests and send out AXI bus
  //
  
  reg [3:0] read_state;
  reg [3:0] read_sent;
  
  assign ARLEN = 4'd0;
  assign ARSIZE = 3'd2;
  assign ARBURST = 2'd0;
  assign ARLOCK = 2'd0;
  assign ARCACHE = 4'd0;
  assign ARPROT = 3'd0;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      read_sent <= 4'd0;
    else
    begin
      read_sent[0] <= (read_sent[0] | (read_state == 4'd1)) && !read_ack[0];
      read_sent[1] <= (read_sent[1] | (read_state == 4'd3)) && !read_ack[1];
      read_sent[2] <= (read_sent[2] | (read_state == 4'd5)) && !read_ack[2];
      read_sent[3] <= (read_sent[3] | (read_state == 4'd7)) && !read_ack[3];
    end
    
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      read_state <= 4'd0;
      ARVALID <= 1'b0;
    end
    else
    begin
      case (read_state[3:0])
      4'd0:
        if (read_sent[0] || !pending_read[0])
          read_state <= read_state + 4'd2;
        else
        begin
          read_state <= read_state + 4'd1;
          ARVALID <= 1'b1;
          ARID <= 2'd0;
          ARADDR <= addr_0;
        end   
      4'd1:
        if (ARREADY)
        begin
          read_state <= read_state + 4'd1;
          ARVALID <= 1'b0;
        end
        
      4'd2:
        if (read_sent[1] || !pending_read[1])
          read_state <= read_state + 4'd2;
        else
        begin
          read_state <= read_state + 4'd1;
          ARVALID <= 1'b1;
          ARID <= 2'd1;
          ARADDR <= addr_1;
        end   
      4'd3:
        if (ARREADY)
        begin
          read_state <= read_state + 4'd1;
          ARVALID <= 1'b0;
        end

      4'd4:
        if (read_sent[2] || !pending_read[2])
          read_state <= read_state + 4'd2;
        else
        begin
          read_state <= read_state + 4'd1;
          ARVALID <= 1'b1;
          ARID <= 2'd2;
          ARADDR <= addr_2;
        end   
      4'd5:
        if (ARREADY)
        begin
          read_state <= read_state + 4'd1;
          ARVALID <= 1'b0;
        end

      4'd6:
        if (read_sent[3] || !pending_read[3])
          read_state <= read_state + 4'd2;
        else
        begin
          read_state <= read_state + 4'd1;
          ARVALID <= 1'b1;
          ARID <= 2'd3;
          ARADDR <= addr_3;
        end   
      4'd7:
        if (ARREADY)
        begin
          read_state <= read_state + 4'd1;
          ARVALID <= 1'b0;
        end
                                                        
      default: read_state <= 4'd0;
      endcase
      
    end

  //
  // Format and send read response data to regfile
  //
  
  reg rvalid_d1;
  reg [1:0] rid_d1;
  reg [63:0] rdata_d1;
  
  always @ (posedge CLK)
  begin
    rvalid_d1 <= RVALID;
    rid_d1 <= RID;
    rdata_d1 <= RDATA;
  end
  
  reg [31:0] axi_word;
  reg [31:0] axi_final;
  reg word_sel;
  reg [3:0] byte_mask;
  
  always @ *
    case (rid_d1[1:0])
    2'd0:
    begin
      word_sel = addr_0[2];
      byte_mask = mask_0;
    end
    2'd1:
    begin
      word_sel = addr_1[2];
      byte_mask = mask_1;
    end
    2'd2:
    begin
      word_sel = addr_2[2];
      byte_mask = mask_2;
    end
    default:
    begin
      word_sel = addr_3[2];
      byte_mask = mask_3;
    end
    endcase
  
  always @ *
  begin
      axi_word = (word_sel) ? rdata_d1[63:32] : rdata_d1[31:0];
      
      case (byte_mask)
      4'b0001: axi_final = {24'd0, axi_word[7:0]};
      4'b0010: axi_final = {24'd0, axi_word[15:8]};
      4'b0100: axi_final = {24'd0, axi_word[23:16]};
      4'b1000: axi_final = {24'd0, axi_word[31:24]};
      4'b0011: axi_final = {16'd0, axi_word[15:0]};
      4'b1100: axi_final = {16'd0, axi_word[31:16]};
      default: axi_final = axi_word;
      endcase
  end
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      AXI_LOAD_VLD <= 1'b0;
    else
      AXI_LOAD_VLD <= rvalid_d1;
  
  always @ (posedge CLK)
  begin    
    AXI_LOAD_SLICE <= rid_d1[1:0];
    AXI_LOAD <= axi_final;
    
    case (rid_d1[1:0])
    2'd0: AXI_LOAD_SEL <= rc_0;
    2'd1: AXI_LOAD_SEL <= rc_1;
    2'd2: AXI_LOAD_SEL <= rc_2;
    default: AXI_LOAD_SEL <= rc_3;
    endcase   
  end
               
endmodule
