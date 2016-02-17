

start:
  jmp(T0_L1);
  jmp(T1_L1);
  
  
T0_L1:
  mv(r15, 0x600); xor(r0, r0);
  mv(r1, r0); mv(r8, r0);
  mv(r2, r0); mv(r9, r0);
  mv(r3, r0); mv(r10, r0);
  mv(r4, r0); mv(r11, r0);
  mv(r5, r0); mv(r12, r0);
  mv(r6, r0); mv(r13, r0);
  mv(r7, r0); mv(r14, r0);
T0_L2:
  br(T0_L2); inc(r0, 1);
  
T1_L1:
  mv(r15, 0x800); xor(r0, r0);
  mv(r7, r0); mv(r14, r0);
  mv(r6, r0); mv(r13, r0);
  mv(r5, r0); mv(r12, r0);
  mv(r4, r0); mv(r11, r0);
  mv(r3, r0); mv(r10, r0);
  mv(r2, r0); mv(r9, r0);
  mv(r1, r0); mv(r8, r0);
T1_L2:
  br(T1_L2); inc(r0, 1);
