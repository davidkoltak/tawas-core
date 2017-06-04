
//
// Tawas Instruction Fetch:
//
// Fetch instructions from the instruction ROM and execute
// BR, CALL, and IMM instructions.  Generate AU and LS opcode
// control output signals for four "slices" (threads).
//
// Slice 0 starts at instruction offset 0x000000
// Slice 1 starts at instruction offset 0x000001
// Slice 2 starts at instruction offset 0x000002
// Slice 3 starts at instruction offset 0x000003
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
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEICSALINGS IN THE
// SOFTWARE.
// 
module tawas_fetch
(
  input CLK,
  input RST,

  output ICS,
  output [23:0] IADDR,
  input [31:0] IDATA,

  output [1:0] SLICE,
  input [7:0] AU_FLAGS,
  input [3:0] RACCOON_STALL,
  
  output PC_STORE,
  output [23:0] PC,
  input [23:0] PC_RTN,

  output RF_IMM_VLD,
  output [3:0] RF_IMM_SEL,
  output [31:0] RF_IMM,

  output AU_OP_VLD,
  output [14:0] AU_OP,
  
  output LS_OP_VLD,
  output [14:0] LS_OP
);

  //
  // PC Generation and Redirection for two threads - BR/CALL Decode
  //
  
  reg au_cond_flag;
  reg au_cond_true;
  
  reg [23:0] pc_next;
  reg [23:0] pc_inc;
  reg pc_stall;
  reg pc_store_en;
  reg r6_push_en;
  
  reg instr_vld;
  reg [1:0] pc_sel;
  reg fetch_stall;
  reg fetch_stall_d1;
  
  reg [23:0] pc;
  reg [23:0] pc_0;
  reg [23:0] pc_1;
  reg [23:0] pc_2;
  reg [23:0] pc_3;
  reg pc_0_nop_loop;
  reg pc_1_nop_loop;
  reg pc_2_nop_loop;
  reg pc_3_nop_loop;
  reg series_cmd_0;
  reg series_cmd_1;
  reg series_cmd_2;
  reg series_cmd_3;
  
  assign SLICE = pc_sel[1:0];
  
  assign PC_STORE = pc_store_en;
  assign PC = pc_inc;
  
  assign IADDR = pc;
  assign ICS = !fetch_stall;
  
  assign cmd_is_nop_loop = instr_vld && (IDATA[31:0] == 32'hC0000000);
  
  always @ *
  begin
    case (IDATA[25:23])
    4'h0: au_cond_flag = AU_FLAGS[0];
    4'h1: au_cond_flag = AU_FLAGS[1];
    4'h2: au_cond_flag = AU_FLAGS[2];
    4'h3: au_cond_flag = AU_FLAGS[3];
    4'h4: au_cond_flag = AU_FLAGS[4];
    4'h5: au_cond_flag = AU_FLAGS[5];
    4'h6: au_cond_flag = AU_FLAGS[6];
    default: au_cond_flag = AU_FLAGS[7];
    endcase
    au_cond_true = au_cond_flag ^ IDATA[26];
  end
  
  always @ *
  begin
    case (pc_sel[1:0])
    2'd0: pc_next = pc_3;
    2'd1: pc_next = pc_0;
    2'd2: pc_next = pc_1;
    default: pc_next = pc_2;
    endcase
    
    case (pc_sel[1:0])
    2'd0: pc_stall = RACCOON_STALL[1] || pc_1_nop_loop;
    2'd1: pc_stall = RACCOON_STALL[2] || pc_2_nop_loop;
    2'd2: pc_stall = RACCOON_STALL[3] || pc_3_nop_loop;
    default: pc_stall = RACCOON_STALL[0] || pc_0_nop_loop;
    endcase
    
    pc_inc = pc_next + 24'd1;
    pc_store_en = 1'b0;
    r6_push_en = 1'b0;
    
    if (IDATA[31:26] == 6'b111111)
    begin
      r6_push_en = IDATA[25];
      pc_store_en = IDATA[24];
      pc_next = IDATA[23:0];
    end
    else if (IDATA[31:29] == 3'b110)
    begin
      if (IDATA[27] == 1'b0)
        pc_next = pc_next + {{12{IDATA[26]}}, IDATA[26:15]};
      else if (IDATA[22:15] == 8'd1)
      begin
        pc_store_en = 1'b1;
        pc_next = PC_RTN;
      end
      else if (au_cond_true)
        pc_next = pc_next + {{16{IDATA[22]}}, IDATA[22:15]};
      else
        pc_next = pc_inc;
    end
    else
      pc_next = pc_inc;
  end

  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      pc_sel <= 2'd0;
      instr_vld <= 1'b0;
      fetch_stall <= 1'b0;
      fetch_stall_d1 <= 1'b0;
    end
    else
    begin
      pc_sel <= pc_sel + 2'd1;
      instr_vld <= 1'b1;
      fetch_stall <= pc_stall;
      fetch_stall_d1 <= fetch_stall;
    end
      
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      pc <= 24'd0;
      pc_0 <= 24'd0;
      pc_1 <= 24'd1;
      pc_2 <= 24'd2;
      pc_3 <= 24'd3;
      pc_0_nop_loop <= 1'b0;
      pc_1_nop_loop <= 1'b0;
      pc_2_nop_loop <= 1'b0;
      pc_3_nop_loop <= 1'b0;
      series_cmd_0 <= 1'b0;
      series_cmd_1 <= 1'b0;
      series_cmd_2 <= 1'b0;
      series_cmd_3 <= 1'b0;
    end
    else if (~instr_vld)
      pc <= pc_1;
    else
    begin
      case (pc_sel[1:0])
      2'd0:
      begin
        pc <= pc_1;
        
        if (fetch_stall_d1)
          pc_3 <= pc_3;
        else if (cmd_is_nop_loop)
          pc_3_nop_loop <= 1'b1;
        else if (!IDATA[31] && !series_cmd_3)
          series_cmd_3 <= 1'b1;
        else
        begin
          pc_3 <= pc_next;
          series_cmd_3 <= 1'b0;
        end
        
      end
      
      2'd1:
      begin
        pc <= pc_2;
          
        if (fetch_stall_d1)
          pc_0 <= pc_0;
        else if (cmd_is_nop_loop)
          pc_0_nop_loop <= 1'b1;
        else if (!IDATA[31] && !series_cmd_0)
          series_cmd_0 <= 1'b1;
        else
        begin
          pc_0 <= pc_next;
          series_cmd_0 <= 1'b0;
        end
        
      end
      
      2'd2:
      begin
        pc <= pc_3;
          
        if (fetch_stall_d1)
          pc_1 <= pc_1;
        else if (cmd_is_nop_loop)
          pc_1_nop_loop <= 1'b1;
        else if (!IDATA[31] && !series_cmd_1)
          series_cmd_1 <= 1'b1;
        else
        begin
          pc_1 <= pc_next;
          series_cmd_1 <= 1'b0;
        end
        
      end
      
      default:
      begin
        pc <= pc_0;
          
        if (fetch_stall_d1)
          pc_2 <= pc_2;
        else if (cmd_is_nop_loop)
          pc_2_nop_loop <= 1'b1;
        else if (!IDATA[31] && !series_cmd_2)
          series_cmd_2 <= 1'b1;
        else
        begin
          pc_2 <= pc_next;
          series_cmd_2 <= 1'b0;
        end
        
      end
      endcase
      
    end

  //
  // Pick opcodes from instruction words
  //  

  reg au_upper;
  wire ls_upper;
  
  always @ *
    case (pc_sel[1:0])
    2'd0: au_upper = series_cmd_3;
    2'd1: au_upper = series_cmd_0;
    2'd2: au_upper = series_cmd_1;
    default: au_upper = series_cmd_2;
    endcase
  
  assign ls_upper = au_upper || (IDATA[31:30] == 2'b10);
  
  assign AU_OP_VLD = !fetch_stall_d1 && ((IDATA[31:30] == 2'b00) || (IDATA[31:30] == 2'b10) || (IDATA[31:28] == 4'b1100));
  assign AU_OP = (au_upper) ? IDATA[30:15] : IDATA[14:0];
  
  assign RF_IMM_VLD = !fetch_stall_d1 && (IDATA[31:28] == 4'hE);
  assign RF_IMM_SEL = IDATA[27:24];
  assign RF_IMM = {{8{IDATA[23]}}, IDATA[23:0]};
  
  assign LS_OP_VLD = !fetch_stall_d1 && (r6_push_en || (IDATA[31:30] == 2'b01) || (IDATA[31:30] == 2'b10) || (IDATA[31:28] == 4'b1101));
  assign LS_OP = (r6_push_en) ? {3'h7, 6'h3F, 3'd7, 3'd6} : (ls_upper) ? IDATA[30:15] : IDATA[14:0];
        
endmodule
