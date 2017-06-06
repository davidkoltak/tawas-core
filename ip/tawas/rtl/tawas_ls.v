
//
// Tawas Load/Store:
//
// Perform load/store operations between the data bus and register file.
//
// by
//   David M. Koltak  02/11/2016
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

module tawas_ls
(
  input CLK,
  input RST,
  
  output reg [31:0] DADDR,
  output reg DCS,
  output reg RACCOON_CS,
  output reg [3:0] WRITEBACK_REG,
  output reg DWR,
  output reg [3:0] DMASK,
  output reg [31:0] DOUT,
  input [31:0] DIN,
  
  input LS_OP_VLD,
  input [14:0] LS_OP,

  input LS_DIR_VLD,
  input LS_DIR_STORE,
  input [3:0] LD_DIR_SEL,
  input [31:0] LD_DIR_ADDR,
  
  output [2:0] LS_PTR_SEL,
  input [31:0] LS_PTR,
  
  output [3:0] LS_STORE_SEL,
  input [31:0] LS_STORE,

  output reg LS_PTR_UPD_VLD,
  output reg [2:0] LS_PTR_UPD_SEL,
  output reg [31:0] LS_PTR_UPD,
  
  output LS_LOAD_VLD,
  output [3:0] LS_LOAD_SEL,
  output [31:0] LS_LOAD
);

  //
  // Instruction decode
  //
  
  reg [8:0] ld_d1;
  reg [8:0] ld_d2;
  reg [8:0] ld_d3;
  
  wire raccoon_space;
  wire [31:0] addr_offset;
  wire [31:0] addr_adj;
  wire [31:0] addr_next;
  wire [31:0] addr_out;
  
  wire [3:0] data_reg;
  
  wire wr_en;
  wire [31:0] wr_data;
  wire [3:0] data_mask;
  
  assign data_reg = (LS_DIR_VLD) ? LD_DIR_SEL : {&LS_OP[12:11], LS_OP[2:0]};
  
  assign LS_PTR_SEL = LS_OP[5:3];
  assign LS_STORE_SEL = data_reg;
  
  assign addr_offset = (LS_OP[12]) ? {{25{1'b0}}, LS_OP[10:6], 2'd0} :
                       (LS_OP[11]) ? {{26{1'b0}}, LS_OP[10:6], 1'd0} 
                                   : {{27{1'b0}}, LS_OP[10:6]};
                    
  assign addr_adj = (LS_OP[12]) ? {{25{LS_OP[10]}}, LS_OP[10:6], 2'd0} :
                    (LS_OP[11]) ? {{26{LS_OP[10]}}, LS_OP[10:6], 1'd0} 
                                : {{27{LS_OP[10]}}, LS_OP[10:6]};
  
  assign addr_next = LS_PTR + ((LS_OP[13]) ? addr_adj : addr_offset);
  assign addr_out = (LD_DIR_VLD) ? LD_DIR_ADDR : (LS_OP[13] && !addr_adj[31]) ? LS_PTR : addr_next;
  
  assign raccoon_space = |addr_out[31:20];
  
  assign wr_en = (LD_DIR_VLD && LD_DIR_STORE) || (LS_OP_VLD && LS_OP[14]);
  
  assign wr_data = (LS_OP[12] || LS_DIR_VLD) ? LS_STORE[31:0] :
                   (LS_OP[11]) ? {LS_STORE[15:0], LS_STORE[15:0]}
                               : {LS_STORE[7:0], LS_STORE[7:0], LS_STORE[7:0], LS_STORE[7:0]};
  
  assign data_mask = (LS_OP[12] || LS_DIR_VLD) ? 4'b1111 :
                     (LS_OP[11]) ? (addr_out[1]) ? 4'b1100 : 4'b0011
                                 : (addr_out[1] && addr_out[0]) ? 4'b1000 :
                                   (addr_out[1]               ) ? 4'b0100 :
                                   (               addr_out[0]) ? 4'b0010
                                                                   : 4'b0001;
      
  //
  // Update pointers
  //
  
  always @ (posedge CLK)
    if (LS_OP_VLD)
    begin
      LS_PTR_UPD_VLD <= LS_OP[13];
      LS_PTR_UPD_SEL <= LS_OP[5:3];
      LS_PTR_UPD <= addr_next;
    end
    else
    begin     
      LS_PTR_UPD_VLD <= 1'b0;
      LS_PTR_UPD_SEL <= 3'b0;
      LS_PTR_UPD <= 32'd0;
    end
      
  //
  // Send no-wait bus request
  //
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      ld_d1 <= 9'd0;
    else if (LS_OP_VLD || LS_DIR_VLD)
      ld_d1 <= {!wr_en && !raccoon_space, LS_OP[12:11], addr_out[1:0], data_reg};
    else
      ld_d1 <= 9'd0;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      {ld_d3, ld_d2} <= {9'd0, 9'd0};
    else
      {ld_d3, ld_d2} <= {ld_d2, ld_d1};
    
  always @ (posedge CLK)
    if (LS_OP_VLD || LS_DIR_VLD)
    begin
      DADDR <= {addr_out[31:2], 2'b00};
      DCS <=  !raccoon_space;
      RACCOON_CS <= raccoon_space;
      WRITEBACK_REG <= data_reg;
      DWR <= wr_en;
      DMASK <= data_mask;
      DOUT <= (wr_en) ? wr_data : 32'd0;
    end
    else
    begin
      DADDR <= 32'd0;
      DCS <= 1'b0;
      RACCOON_CS <= 1'b0;
      WRITEBACK_REG <= 4'd0;
      DWR <= 1'b0;
      DMASK <= 4'b0000;
      DOUT <= 32'd0;
    end
    
  //
  // Register no-wait read data (D BUS) and send to regfile
  //
  
  reg [31:0] rd_data;
  wire [31:0] rd_data_final;
  
  always @ (posedge CLK)
    if (ld_d2[8])
      rd_data <= DIN;
  
  assign rd_data_final = (ld_d3[7]) ? rd_data :
                         (ld_d3[6]) ? (ld_d3[5]) ? {16'd0, rd_data[31:16]}
                                                 : {16'd0, rd_data[15:0]}
                                    : (ld_d3[5] && ld_d3[4]) ? {24'd0, rd_data[31:24]} :
                                      (ld_d3[5]            ) ? {24'd0, rd_data[23:16]} :
                                      (            ld_d3[4]) ? {24'd0, rd_data[15:8]}
                                                             : {24'd0, rd_data[7:0]};        
  
  assign LS_LOAD_VLD = ld_d3[8];
  assign LS_LOAD_SEL = ld_d3[3:0];
  assign LS_LOAD = rd_data_final;
  
endmodule
  
