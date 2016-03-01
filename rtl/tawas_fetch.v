
//
// Tawas Instruction Fetch:
//
// Fetch instructions from the instruction ROM and execute
// BR, CALL, and IMM instructions.  Generate AU and LS opcode
// control output signals for two "slices" (threads).
//
// Slice 0 starts at instruction offset 0x000000
// Slice 1 starts at instruction offset 0x000001
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
module tawas_fetch
(
  input CLK,
  input RST,

  output [23:0] IADDR,
  input [31:0] IDATA,

  output SLICE,
  input [7:0] AU_FLAGS,
  
  output PC_STORE,
  output [23:0] PC,
  input [23:0] PC_RTN,
  
  output EC_STORE,
  output [31:0] EC,

  output AU_OP_VLD,
  output [14:0] AU_OP,

  output AU_OP_IMM_VLD,
  output [27:0] AU_OP_IMM,

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
  reg ec_store_en;
  reg pc_store_en;
  reg r7_pp_en;
  
  reg instr_vld;
  reg pc_sel;
  
  reg [23:0] pc;
  reg [23:0] pc_0;
  reg [23:0] pc_1;
  reg series_cmd_0;
  reg series_cmd_1;
  
  assign SLICE = ~pc_sel;
  
  assign PC_STORE = pc_store_en;
  assign PC = pc_inc;
  
  assign EC_STORE = ec_store_en;
  assign EC = {{8{IDATA[23]}}, IDATA[23:0]};
  
  assign IADDR = pc;
  
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
    pc_next = (pc_sel) ? pc_0 : pc_1;
    pc_inc = pc_next + 24'd1;
    r7_pp_en = 1'b0;
    ec_store_en = 1'b0;
    pc_store_en = 1'b0;
    
    if (IDATA[31:28] == 4'b1111)
    begin
      r7_pp_en = IDATA[27];
      ec_store_en = IDATA[26];
      pc_store_en = IDATA[25];
      pc_next = (IDATA[24]) ? PC_RTN : IDATA[23:0];
    end
    else if (IDATA[31:29] == 3'b110)
    begin
      if (IDATA[27] == 1'b1)
        pc_next = pc_next + {{12{IDATA[26]}}, IDATA[26:15]};
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
      pc_sel <= 1'b0;
      instr_vld <= 1'b0;
    end
    else
    begin
      pc_sel <= ~pc_sel;
      instr_vld <= 1'b1;
    end
      
  always @ (posedge CLK or posedge RST)
    if (RST)
    begin
      pc <= 24'd0;
      pc_0 <= 24'd0;
      pc_1 <= 24'd1;
      series_cmd_0 <= 1'b0;
      series_cmd_1 <= 1'b0;
    end
    else if (~instr_vld)
      pc <= pc_1;
    else
    begin
      if (pc_sel)
      begin
        if ((IDATA[31]) || series_cmd_0)
        begin
          pc <= pc_next;
          pc_0 <= pc_next;
          series_cmd_0 <= 1'b0;
        end
        else
        begin
          pc <= pc_0;
          series_cmd_0 <= 1'b1;
        end
      end
      else
      begin
        if ((IDATA[31]) || series_cmd_1)
        begin
          pc <= pc_next;
          pc_1 <= pc_next;
          series_cmd_1 <= 1'b0;
        end
        else
        begin
          pc <= pc_1;
          series_cmd_1 <= 1'b1;
        end
      end
    end

  //
  // Pick opcodes from instruction words
  //  

  wire au_upper;
  wire ls_upper;
  
  assign au_upper = (pc_sel) ? series_cmd_0 : series_cmd_1;
  assign ls_upper = au_upper || (IDATA[31:30] == 2'b10);
  
  assign AU_OP_VLD = (IDATA[31:30] == 2'b00) || (IDATA[31:30] == 2'b10) || (IDATA[31:28] == 4'b1100);
  assign AU_OP = (au_upper) ? IDATA[30:15] : IDATA[14:0];
  
  assign AU_OP_IMM_VLD = (IDATA[31:28] == 4'hE);
  assign AU_OP_IMM = IDATA[27:0];
  
  wire [14:0] r7_pp_instr;
  
  assign r7_pp_instr = (pc_store_en) ? {3'h7, 6'h3F, 3'd6, 3'd7} : {3'h3, 6'h1, 3'd6, 3'd7};
  
  assign LS_OP_VLD = r7_pp_en || (IDATA[31:30] == 2'b01) || (IDATA[31:30] == 2'b10) || (IDATA[31:28] == 4'b1101);
  assign LS_OP = (r7_pp_en) ? r7_pp_instr : (ls_upper) ? IDATA[30:15] : IDATA[14:0];
        
endmodule
