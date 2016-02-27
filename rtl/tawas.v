
//
// Tawas Module Toplevel: A simple multi-threaded RISC core.
//
// by
//   David M. Koltak  02/11/2016
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

  wire slice;
  
  wire pc_store;
  wire [23:0] pc;
  wire [23:0] pc_rtn;
  wire e_store;
  wire [31:0] e_value;
  
  wire [15:0] au_flags;
  wire au_op_vld;
  wire [4:0] au_op;
  wire [2:0] au_op_ra;
  wire [2:0] au_op_rb;
  wire [2:0] au_op_rc;
  wire au_op_imm_vld;
  wire [31:0] au_op_imm;
  
  wire ls_op_vld;
  wire ls_op_store;
  wire ls_op_ptr_upd;
  wire [1:0] ls_op_type;
  wire [2:0] ls_op_ptr;
  wire [5:0] ls_op_offset;
  wire [2:0] ls_op_reg;
  
  tawas_fetch tawas_fetch
  (
    .CLK(CLK),
    .RST(RST),
    
    .IADDR(IADDR),
    .IDATA(IDATA),
    
    .SLICE(slice),
    
    .PC_STORE(pc_store),
    .PC(pc),
    .PC_RTN(pc_rtn),
  
    .E_STORE(e_store),
    .E(e_value),
    
    .AU_FLAGS(au_flags),
    
    .AU_OP_VLD(au_op_vld),
    .AU_OP(au_op),
    .AU_OP_RA(au_op_ra),
    .AU_OP_RB(au_op_rb),
    .AU_OP_RC(au_op_rc),
    
    .AU_OP_IMM_VLD(ap_op_imm_vld),
    .AU_OP_IMM(au_op_imm),
    
    .LS_OP_VLD(ls_op_vld),
    .LS_OP_STORE(ls_op_store),
    .LS_OP_PTR_UPD(ls_op_ptr_upd),
    .LS_OP_TYPE(ls_op_type),
    .LS_OP_PTR(ls_op_ptr),
    .LS_OP_OFFSET(ls_op_offset),
    .LS_OP_REG(ls_op_reg)
  );
  
  wire [3:0] au_ra_sel;
  wire [31:0] au_ra;
  wire [3:0] au_rb_sel;
  wire [31:0] au_rb;
  wire au_rd_vld;
  wire [3:0] au_rd_sel;
  wire [31:0] au_rd;
  
  tawas_au tawas_au
  (
    .CLK(CLK),
    .RST(RST),
    
    .AU_FLAGS(au_flags),
    
    .AU_OP_VLD(au_op_vld),
    .AU_OP(au_op),
    .AU_OP_RA(au_op_ra),
    .AU_OP_RB(au_op_rb),
    
    .AU_OP_IMM_VLD(ap_op_imm_vld),
    .AU_OP_IMM(au_op_imm),
     
    .AU_RA_SEL(au_ra_sel),
    .AU_RA(au_ra),
    .AU_RB_SEL(au_rb_sel),
    .AU_RB(au_rb),
    
    .AU_RD_VLD(au_rd_vld),
    .AU_RD_SEL(au_rd_sel),
    .AU_RD(au_rd)
  );
  
  wire [31:0] ls_ptr;
  wire [31:0] ls_store_data;
  
  wire ls_ptr_upd_vld;
  wire [2:0] ls_ptr_upd_sel;
  wire [31:0] ls_ptr_upd;
  
  wire ls_load_vld;
  wire [3:0] ls_load_sel;
  wire [31:0] ls_load_data;
  
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
    .LS_OP_STORE(ls_op_store),
    .LS_OP_TYPE(ls_op_type),
    .LS_OP_OFFSET(ls_op_offset),
    .LS_OP_REG(ls_op_reg),
    
    .LS_PTR(ls_ptr),
    .LS_STORE_DATA(ls_store_data),
    
    .LS_LOAD_VLD(ls_load_vld),
    .LS_LOAD_SEL(ls_load_sel),
    .LS_LOAD_DATA(ls_load_data)
  );
  
  tawas_regfile tawas_regfile
  (
    .CLK(CLK),
    .RST(RST),
    
    .SLICE(slice),
    
    .PC_STORE(pc_store),
    .PC(pc),
    .PC_RTN(pc_rtn),
    
    .E_STORE(e_store),
    .E(e_value),
    
    .AU_RA_SEL(au_ra_sel),
    .AU_RA(au_ra),
    .AU_RB_SEL(au_rb_sel),
    .AU_RB(au_rb),
    
    .AU_RD_VLD(au_rd_vld),
    .AU_RD_SEL(au_rd_sel),
    .AU_RD(au_rd),
    
    .LS_PTR_REG(ls_op_ptr),
    .LS_PTR(ls_ptr),
    
    .LS_STORE_SEL(ls_op_reg),
    .LS_STORE_DATA(ls_store_data),
    
    .LS_PTR_UPD_VLD(ls_ptr_upd_vld),
    .LS_PTR_UPD_SEL(ls_ptr_upd_sel),
    .LS_PTR_UPD(ls_ptr_upd),
    
    .LS_LOAD_VLD(ls_load_vld),
    .LS_LOAD_SEL(ls_load_sel),
    .LS_LOAD_DATA(ls_load_data)    
  );
  
endmodule
