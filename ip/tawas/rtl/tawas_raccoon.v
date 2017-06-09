
//
// Tawas Raccoon bus interface:
//
// Perform load/store operations over Raccoon. Stall issueing thread while transaction is pending.
//
// by
//   David M. Koltak  11/01/2016
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

module tawas_raccoon
(
  input CLK,
  input RST,

  input [1:0] SLICE,
  output [3:0] RACCOON_STALL,
  
  input [31:0] DADDR,
  input RACCOON_CS,
  input [3:0] WRITEBACK_REG,
  input DWR,
  input [3:0] DMASK,
  input [31:0] DOUT,
      
  output reg RACCOON_LOAD_VLD,
  output reg [1:0] RACCOON_LOAD_SLICE,
  output reg [3:0] RACCOON_LOAD_SEL,
  output reg [31:0] RACCOON_LOAD,
  
  output [63:0] RaccOut,
  input [63:0] RaccIn
);
  parameter ID_UPPER = 6'd0;
  
  //
  // Register Raccoon bus input/output
  //
  
  reg [63:0] racc_in;
  reg [63:0] racc_out;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      racc_in <= 64'd0;
    else
      racc_in <= RaccIn;
  
  assign RaccOut = racc_out;
  
  //
  // Pending transactions... one per thread
  //
  
  reg [3:0] bus_req;
  reg [3:0] thread_mask;
  reg [3:0] bus_ack;
  reg [3:0] bus_retry;
  reg [3:0] bus_pending;
  
  always @ *
  begin
    bus_req = 4'd0;
    bus_ack = 4'd0;
    bus_retry = 4'd0;
    
    if (RACCOON_CS)
      case (SLICE[1:0])
      2'd0: bus_req = 4'b0100;
      2'd1: bus_req = 4'b1000;
      2'd2: bus_req = 4'b0001;
      default: bus_req = 4'b0010;
      endcase
    
    case (racc_in[61:54])
    {ID_UPPER, 2'd0}: thread_mask = 4'b0001;
    {ID_UPPER, 2'd1}: thread_mask = 4'b0010;
    {ID_UPPER, 2'd2}: thread_mask = 4'b0100;
    {ID_UPPER, 2'd3}: thread_mask = 4'b1000;
    default: thread_mask = 4'd0;
    endcase
    
    if (racc_in[63] && !racc_in[62])
      bus_ack = thread_mask;
      
    if ((racc_in[63] && racc_in[62]))
      bus_retry = thread_mask;
      
  end
  
  assign RACCOON_STALL = bus_pending;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      bus_pending <= 4'd0;
    else
      bus_pending <= (bus_pending & ~bus_ack) | bus_req;
      
  //
  // Transaction data
  //
  
  reg [19:2] addr_0;
  reg [19:2] addr_1;
  reg [19:2] addr_2;
  reg [19:2] addr_3;
  
  reg [3:0] mask_0;
  reg [3:0] mask_1;
  reg [3:0] mask_2;
  reg [3:0] mask_3;
  
  reg [31:0] dout_0;
  reg [31:0] dout_1;
  reg [31:0] dout_2;
  reg [31:0] dout_3;
  
  reg [3:0] rc_0;
  reg [3:0] rc_1;
  reg [3:0] rc_2;
  reg [3:0] rc_3;
  
  always @ (posedge CLK)
    if (bus_req[0])
    begin
      addr_0 <= DADDR[19:2];
      mask_0 <= (DWR) ? DMASK : 4'd0;
      dout_0 <= DOUT;
      rc_0 <= WRITEBACK_REG;
    end

  always @ (posedge CLK)
    if (bus_req[1])
    begin
      addr_1 <= DADDR[19:2];
      mask_1 <= (DWR) ? DMASK : 4'd0;
      dout_1 <= DOUT;
      rc_1 <= WRITEBACK_REG;
    end
    
  always @ (posedge CLK)
    if (bus_req[2])
    begin
      addr_2 <= DADDR[19:2];
      mask_2 <= (DWR) ? DMASK : 4'd0;
      dout_2 <= DOUT;
      rc_2 <= WRITEBACK_REG;
    end
    
  always @ (posedge CLK)
    if (bus_req[3])
    begin
      addr_3 <= DADDR[19:2];
      mask_3 <= (DWR) ? DMASK : 4'd0;
      dout_3 <= DOUT;
      rc_3 <= WRITEBACK_REG;
    end

  //
  // Arbitrate requests and send out Raccoon bus
  //
  
  reg [1:0] bus_state;
  reg [3:0] bus_sent;
  reg [2:0] bus_sent_mark;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      bus_sent <= 4'd0;
    else
    begin
      bus_sent[0] <= (bus_sent[0] || (bus_sent_mark == 3'b100)) && !bus_ack[0] && !bus_retry[0];
      bus_sent[1] <= (bus_sent[1] || (bus_sent_mark == 3'b101)) && !bus_ack[1] && !bus_retry[1];
      bus_sent[2] <= (bus_sent[2] || (bus_sent_mark == 3'b110)) && !bus_ack[2] && !bus_retry[2];
      bus_sent[3] <= (bus_sent[3] || (bus_sent_mark == 3'b111)) && !bus_ack[3] && !bus_retry[3];
    end
    
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      bus_state <= 2'd0;
      bus_sent_mark <= 3'b000;
      racc_out <= 64'd0;
    end
    else if (racc_in[63] && (racc_in[61:56] != ID_UPPER))
    begin
      bus_sent_mark <= 3'b000;
      racc_out <= racc_in;
    end
    else
    begin
      bus_state <= bus_state + 2'd1;
      case (bus_state[1:0])
      2'd0:
        if (bus_pending[0] && !bus_sent[0])
        begin
          bus_sent_mark <= 3'b100;
          racc_out <= {2'b11, ID_UPPER, 2'd0, mask_0, addr_0, dout_0};
        end
        else
        begin 
          bus_sent_mark <= 3'b000;
          racc_out <= 64'd0;
        end
        
      2'd1:
        if (bus_pending[1] && !bus_sent[1])
        begin
          bus_sent_mark <= 3'b101;
          racc_out <= {2'b11, ID_UPPER, 2'd0, mask_1, addr_1, dout_1};
        end
        else
        begin 
          bus_sent_mark <= 3'b000;
          racc_out <= 64'd0;
        end  
        
      2'd2:
        if (bus_pending[2] && !bus_sent[2])
        begin
          bus_sent_mark <= 3'b110;
          racc_out <= {2'b11, ID_UPPER, 2'd0, mask_2, addr_2, dout_2};
        end
        else
        begin 
          bus_sent_mark <= 3'b000;
          racc_out <= 64'd0;
        end     
      
      default:
        if (bus_pending[3] && !bus_sent[3])
        begin
          bus_sent_mark <= 3'b111;
          racc_out <= {2'b11, ID_UPPER, 2'd0, mask_3, addr_3, dout_3};
        end
        else
        begin 
          bus_sent_mark <= 3'b000;
          racc_out <= 64'd0;
        end
        
      endcase
      
    end

  //
  // Format and send read response data to regfile
  //
  
  reg store_vld;
  reg [31:0] store_pre;
  reg [3:0] store_mask;
  reg [3:0] store_rc;
  reg [31:0] store_final;
  
  always @ *
  begin
      store_pre = racc_in[31:0];

     case (racc_in[55:54])
     2'd0: store_vld = (mask_0 == 4'd0);
     2'd1: store_vld = (mask_1 == 4'd0);
     2'd2: store_vld = (mask_2 == 4'd0);
     default: store_vld = (mask_3 == 4'd0);
     endcase 
           
     case (racc_in[55:54])
     2'd0: store_mask = mask_0;
     2'd1: store_mask = mask_1;
     2'd2: store_mask = mask_2;
     default: store_mask = mask_3;
     endcase 
           
     case (racc_in[55:54])
     2'd0: store_rc = rc_0;
     2'd1: store_rc = rc_1;
     2'd2: store_rc = rc_2;
     default: store_rc = rc_3;
     endcase 
    
      case (store_mask[3:0])
      4'b0001: store_final = {24'd0, store_pre[7:0]};
      4'b0010: store_final = {24'd0, store_pre[15:8]};
      4'b0100: store_final = {24'd0, store_pre[23:16]};
      4'b1000: store_final = {24'd0, store_pre[31:24]};
      4'b0011: store_final = {16'd0, store_pre[15:0]};
      4'b1100: store_final = {16'd0, store_pre[31:16]};
      default: store_final = store_pre;
      endcase
  end
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      RACCOON_LOAD_VLD <= 1'b0;
    else
      RACCOON_LOAD_VLD <= (|bus_ack[3:0]) && store_vld;
  
  always @ (posedge CLK)
  begin    
    RACCOON_LOAD_SLICE <= racc_in[55:54];
    RACCOON_LOAD <= store_final;
    RACCOON_LOAD_SEL <= store_rc;
  end
               
endmodule
