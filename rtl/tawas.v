
//
// Tawas Module Toplevel: A simple multi-threaded RISC core.
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

module tawas
(
  input CLK,
  input RST,
  
  output [23:0] IADDR,
  input [31:0] IDATA,
  
  output [31:0] DADDR,
  output DCS,
  output DWR,
  output [3:0] DMASK,
  output [31:0] DOUT,
  input [31:0] DIN
);
  
  wire pc_store;
  wire [23:0] pc;
  wire [23:0] pc_rtn;
  
  wire rf_imm_vld;
  wire [2:0] rf_imm_sel;
  wire [31:0] rf_imm;
  
  wire slice;
  wire [7:0] au_flags;
  
  wire au_op_vld;
  wire [14:0] au_op;

  wire au_imm_vld;
  wire [27:0] au_imm;
  
  wire ls_op_vld;
  wire [14:0] ls_op;
  
  tawas_fetch tawas_fetch
  (
    .CLK(CLK),
    .RST(RST),
    
    .IADDR(IADDR),
    .IDATA(IDATA),
    
    .SLICE(slice),
    .AU_FLAGS(au_flags),
    
    .PC_STORE(pc_store),
    .PC(pc),
    .PC_RTN(pc_rtn),

    .RF_IMM_VLD(rf_imm_vld),
    .RF_IMM_SEL(rf_imm_sel),
    .RF_IMM(rf_imm),
    
    .AU_OP_VLD(au_op_vld),
    .AU_OP(au_op),
    
    .AU_IMM_VLD(au_imm_vld),
    .AU_IMM(au_imm),
    
    .LS_OP_VLD(ls_op_vld),
    .LS_OP(ls_op)
  );
  
  wire [2:0] au_ra_sel;
  wire [31:0] au_ra;
  
  wire [2:0] au_rb_sel;
  wire [31:0] au_rb;
  
  wire au_rc_vld;
  wire [2:0] au_rc_sel;
  wire [31:0] au_rc;
  
  tawas_au tawas_au
  (
    .CLK(CLK),
    .RST(RST),
    
    .SLICE(slice),
    .AU_FLAGS(au_flags),
    
    .AU_OP_VLD(au_op_vld),
    .AU_OP(au_op),
    
    .AU_IMM_VLD(au_imm_vld),
    .AU_IMM(au_imm),
     
    .AU_RA_SEL(au_ra_sel),
    .AU_RA(au_ra),
    
    .AU_RB_SEL(au_rb_sel),
    .AU_RB(au_rb),
    
    .AU_RC_VLD(au_rc_vld),
    .AU_RC_SEL(au_rc_sel),
    .AU_RC(au_rc)
  );
  
  wire [2:0] ls_ptr_sel;
  wire [31:0] ls_ptr;
  
  wire [2:0] ls_store_sel;
  wire [31:0] ls_store;
  
  wire ls_ptr_upd_vld;
  wire [2:0] ls_ptr_upd_sel;
  wire [31:0] ls_ptr_upd;
  
  wire ls_load_vld;
  wire [2:0] ls_load_sel;
  wire [31:0] ls_load;
  
  tawas_ls tawas_ls
  (
    .CLK(CLK),
    .RST(RST),
    
    .DADDR(DADDR),
    .DCS(DCS),
    .DWR(DWR),
    .DMASK(DMASK),
    .DOUT(DOUT),
    .DIN(DIN),
  
    .LS_OP_VLD(ls_op_vld),
    .LS_OP(ls_op),
    
    .LS_PTR_SEL(ls_ptr_sel),
    .LS_PTR(ls_ptr),
    
    .LS_STORE_SEL(ls_store_sel),
    .LS_STORE(ls_store),
    
    .LS_PTR_UPD_VLD(ls_ptr_upd_vld),
    .LS_PTR_UPD_SEL(ls_ptr_upd_sel),
    .LS_PTR_UPD(ls_ptr_upd),
    
    .LS_LOAD_VLD(ls_load_vld),
    .LS_LOAD_SEL(ls_load_sel),
    .LS_LOAD(ls_load)
  );
  
  tawas_regfile tawas_regfile
  (
    .CLK(CLK),
    .RST(RST),
    
    .SLICE(slice),
    
    .PC_STORE(pc_store),
    .PC(pc),
    .PC_RTN(pc_rtn),

    .RF_IMM_VLD(rf_imm_vld),
    .RF_IMM_SEL(rf_imm_sel),
    .RF_IMM(rf_imm),
  
    .AU_RA_SEL(au_ra_sel),
    .AU_RA(au_ra),
    
    .AU_RB_SEL(au_rb_sel),
    .AU_RB(au_rb),
    
    .AU_RC_VLD(au_rc_vld),
    .AU_RC_SEL(au_rc_sel),
    .AU_RC(au_rc),
    
    .LS_PTR_SEL(ls_ptr_sel),
    .LS_PTR(ls_ptr),
    
    .LS_STORE_SEL(ls_store_sel),
    .LS_STORE(ls_store),
    
    .LS_PTR_UPD_VLD(ls_ptr_upd_vld),
    .LS_PTR_UPD_SEL(ls_ptr_upd_sel),
    .LS_PTR_UPD(ls_ptr_upd),
    
    .LS_LOAD_VLD(ls_load_vld),
    .LS_LOAD_SEL(ls_load_sel),
    .LS_LOAD(ls_load)    
  );
  
endmodule
