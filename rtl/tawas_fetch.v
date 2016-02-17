
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

module tawas_fetch
(
  input CLK,
  input RST,

  output [23:0] IADDR,
  input [31:0] IDATA,

  output SLICE,
  
  output PC_STORE,
  output [3:0] PC_STORE_REG,
  output [23:0] PC,

  output [3:0] PC_LOAD_REG,
  input [23:0] PC_RTN,

  input [15:0] AU_FLAGS,

  output AU_OP_VLD,
  output [5:0] AU_OP,
  output [3:0] AU_OP_RA,
  output [3:0] AU_OP_RB,

  output AU_OP_IMM_VLD,
  output [31:0] AU_OP_IMM,

  output LS_OP_VLD,
  output LS_OP_STORE,
  output [1:0] LS_OP_TYPE,
  output [3:0] LS_OP_PTR,
  output [3:0] LS_OP_OFFSET,
  output [3:0] LS_OP_REG
);

  //
  // PC Generation and Redirection for two threads - BR/CALL Decode
  //
  
  reg [3:0] au_cond_sel;
  reg au_cond_true;
  
  reg [23:0] pc_next;
  reg [23:0] pc_inc;
  reg pc_store_en;
  reg [3:0] pc_store_sel;
  
  reg instr_vld;
  reg pc_sel;
  
  reg [23:0] pc;
  reg [23:0] pc_0;
  reg [23:0] pc_1;
  reg series_cmd_0;
  reg series_cmd_1;
  
  assign SLICE = ~pc_sel;
  
  assign PC_STORE = pc_store_en;
  assign PC_STORE_REG = pc_store_sel;
  assign PC = pc_inc;
  assign PC_LOAD_REG = (IDATA[31:30] == 2'b11) ? IDATA[18:15] : 4'd0;
  
  assign IADDR = pc;
  
  always @ *
  begin
    au_cond_sel = 4'd0;
    
    if (IDATA[31:29] == 3'b110)
    begin
      if (IDATA[27:26] == 2'b10)
        au_cond_sel = IDATA[25:22];
      else if (IDATA[27] == 1'b0)
        au_cond_sel = IDATA[26:23];
    end
    
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
    
    pc_store_en = 1'b0;
    pc_store_sel = 4'd0;
    
    if (au_cond_true)
    begin   
      if (IDATA[31:28] == 4'b1111)
      begin
        pc_next = IDATA[23:0];
        pc_store_en = (IDATA[27:24] != 4'b0000);
        pc_store_sel = IDATA[27:24];
      end
      else if (IDATA[31:29] == 3'b110)
      begin
        if (IDATA[27] == 1'b0)
        begin
          pc_next = PC_RTN;
          pc_store_en = 1'b1;
          pc_store_sel = IDATA[22:19];
        end
        else if (IDATA[27:26] == 2'b11)
          pc_next = pc_next + {{13{IDATA[25]}}, IDATA[25:15]};
        else
          pc_next = pc_next + {{17{IDATA[21]}}, IDATA[21:15]};
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
  
  wire au_rega;
  
  assign AU_OP_VLD = (IDATA[31:30] == 2'b00) || (IDATA[31:30] == 2'b10) || (IDATA[31:28] == 4'b1100);
  assign AU_OP = (au_upper) ? IDATA[28:23] : IDATA[13:8];
  assign au_rega = (au_upper) ? IDATA[22:19] : IDATA[7:4];
  assign AU_OP_RA = au_rega;
  
  assign AU_OP_RB = (au_upper) ? IDATA[18:15] : IDATA[3:0];

  assign AU_OP_IMM_VLD = (au_upper) ? IDATA[29] : IDATA[14];
  assign AU_OP_IMM[31:4] = (pc_sel) ? imm_hold_0 : imm_hold_1;
  assign AU_OP_IMM[3:0] = au_rega;

  assign LS_OP_VLD = (IDATA[31:30] == 2'b01) || (IDATA[31:30] == 2'b10) || (IDATA[31:28] == 4'b1101);
  assign LS_OP_STORE = (ls_upper) ? IDATA[29] : IDATA[14];
  assign LS_OP_TYPE = (ls_upper) ? IDATA[28:27] : IDATA[13:12];
  assign LS_OP_PTR = (ls_upper) ? IDATA[26:23] : IDATA[11:8];
  assign LS_OP_OFFSET = (ls_upper) ? IDATA[22:19] : IDATA[7:4];
  assign LS_OP_REG = (ls_upper) ? IDATA[18:15] : IDATA[3:0];
               
endmodule
