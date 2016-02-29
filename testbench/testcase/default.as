

start:
  jmp(T0_L1);
  jmp(T1_L1);
  
  
T0_L1:
  mv(r7, 0x600); inc(r0, 1);
  mv(r1, r0); inc(r0, 1);
  mv(r2, r0); inc(r0, 1);
  mv(r3, r0); inc(r0, 1);
  mv(r4, r0); inc(r0, 1);
  mv(r5, r0); inc(r0, 1);
  mv(r6, r0); inc(r0, 1);
  st(w, r6, r7[5]); nop();
  nop(); nop();
  ld(w, r5, r7[5]); st(w, r5, r7[3]);
  nop(); nop();
T0_L2:
  br(T0_L2); inc(r0, 1);
  
T1_L1:
  mv(r7, 0x800); inc(r0, 3);
  mv(r1, r0); inc(r0, 3);
  mv(r2, r0); inc(r0, 3);
  mv(r3, r0); inc(r0, 3);
  mv(r4, r0); inc(r0, 3);
  mv(r5, r0); inc(r0, 3);
  mv(r6, r0); inc(r0, 3);
  push(r3); nop();
  nop(); nop();
  pop(r2); nop();
  nop(); nop();
T1_L2:
  br(T1_L2); inc(r0, 1);
