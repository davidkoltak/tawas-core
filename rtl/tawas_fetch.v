
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
  input [15:0] AU_FLAGS,
  
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
  
  reg [3:0] au_cond_sel;
  reg au_cond_true;
  
  reg [23:0] pc_next;
  reg [23:0] pc_inc;
  reg [23:0] pc_adj;
  reg ec_store_en;
  reg pc_store_en;
  
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
      
    if ((IDATA[31:29] == 3'b110) && (IDATA[27] == 1'b0))
      au_cond_sel = IDATA[26:23];
    else
      au_cond_sel = 4'd0;
    
    case (au_cond_sel)
    4'h0: au_cond_true = AU_FLAGS[0];
    4'h1: au_cond_true = AU_FLAGS[1];
    4'h2: au_cond_true = AU_FLAGS[2];
    4'h3: au_cond_true = AU_FLAGS[3];
    4'h4: au_cond_true = AU_FLAGS[4];
    4'h5: au_cond_true = AU_FLAGS[5];
    4'h6: au_cond_true = AU_FLAGS[6];
    4'h7: au_cond_true = AU_FLAGS[7];
    4'h8: au_cond_true = AU_FLAGS[8];
    4'h9: au_cond_true = AU_FLAGS[9];
    4'hA: au_cond_true = AU_FLAGS[10];
    4'hB: au_cond_true = AU_FLAGS[11];
    4'hC: au_cond_true = AU_FLAGS[12];
    4'hD: au_cond_true = AU_FLAGS[13];
    4'hE: au_cond_true = AU_FLAGS[14];
    default: au_cond_true = AU_FLAGS[15];
    endcase
  end
  
  always @ *
  begin
    pc_next = (pc_sel) ? pc_0 : pc_1;
    pc_inc = pc_next + 24'd1;
    ec_store_en = 1'b0;
    pc_store_en = 1'b0;
    
    if (au_cond_true)
    begin   
      if (IDATA[31:28] == 4'b1111)
      begin
        ec_store_en = IDATA[27];
        pc_store_en = IDATA[26];
        pc_adj = (IDATA[25]) ? PC_RTN : IDATA[23:0];
        pc_next = (IDATA[24]) ? pc_next + pc_adj : pc_adj;
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
  // Immediate Data holding register
  //
  
  reg [27:0] imm_hold_0;
  reg [27:0] imm_hold_1;
  
  always @ (posedge CLK or posedge RST)
    if (RST)
      imm_hold_0 <= 28'd0;
    else if ((pc_sel) && (IDATA[31:28] == 4'hE))
      imm_hold_0 <= IDATA[28:0];

  always @ (posedge CLK or posedge RST)
    if (RST)
      imm_hold_1 <= 28'd0;
    else if ((~pc_sel) && (IDATA[31:28] == 4'hE))
      imm_hold_1 <= IDATA[28:0];

  //
  // Pick opcodes from instruction words
  //  

  wire au_upper;
  wire ls_upper;
  
  assign au_upper = (pc_sel) ? series_cmd_0 : series_cmd_1;
  assign ls_upper = au_upper || (IDATA[31:0] == 2'b10);
  
  assign AU_OP_VLD = (IDATA[31:30] == 2'b00) || (IDATA[31:30] == 2'b10) || (IDATA[31:28] == 4'b1100);
  assign AU_OP = (au_upper) ? IDATA[30:15] : IDATA[14:0];
  
  assign AU_OP_IMM_VLD = (IDATA[31:28] == 4'hE);
  assign AU_OP_IMM = IDATA[27:0];
  
  assign LS_OP_VLD = (IDATA[31:30] == 2'b01) || (IDATA[31:30] == 2'b10) || (IDATA[31:28] == 4'b1101);
  assign LS_OP = (ls_upper) ? IDATA[30:15] : IDATA[14:0];
  
  /* OLD STUFF
  
  wire au_imm_vld;
  wire [2:0] au_rega;
  wire [1:0] ls_type;
  
  assign AU_OP_VLD = (IDATA[31:30] == 2'b00) || (IDATA[31:30] == 2'b10) || (IDATA[31:28] == 4'b1100);
  
  assign au_imm_vld = (au_upper) ? IDATA[29] : IDATA[14];
  assign AU_OP = ((au_upper) ? IDATA[28:24] : IDATA[13:9]) & ((au_imm_vld) ? 5'h0F : 5'h1F);
  
  assign au_rega = (au_upper) ? IDATA[23:21] : IDATA[8:6];
  assign AU_OP_RA = au_rega;
  
  assign AU_OP_RB = (au_upper) ? IDATA[20:18] : IDATA[5:3];
  assign AU_OP_RC = (au_upper) ? IDATA[17:15] : IDATA[2:0];

  assign AU_OP_IMM_VLD = au_imm_vld;
  assign AU_OP_IMM[31:4] = (pc_sel) ? imm_hold_0 : imm_hold_1;
  assign AU_OP_IMM[3] = (au_upper) ? IDATA[28] : IDATA[13];
  assign AU_OP_IMM[2:0] = au_rega;

  assign LS_OP_VLD = (IDATA[31:30] == 2'b01) || (IDATA[31:30] == 2'b10) || (IDATA[31:28] == 4'b1101);
  assign LS_OP_STORE = (ls_upper) ? IDATA[29] : IDATA[14];
  assign LS_OP_PTR_UPD = (ls_upper) ? IDATA[28] : IDATA[13];
  
  assign ls_type = (ls_upper) ? IDATA[27:26] : IDATA[12:11];
  assign LS_OP_TYPE = ls_type;
  
  assign LS_OP_OFFSET = ((ls_upper) ? IDATA[26:21] : IDATA[11:6]) & ((ls_type[1]) ? 6'h3F : 6'h1F);
  assign LS_OP_PTR = (ls_upper) ? IDATA[20:18] : IDATA[5:3];
  assign LS_OP_REG = (ls_upper) ? IDATA[17:15] : IDATA[2:0];
  
  */
        
endmodule
