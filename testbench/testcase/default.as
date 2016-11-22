

start:
  jmp(T0_L1);
  jmp(T1_L1);
  jmp(T2_L1);
  jmp(T3_L1);
  
  .expr ($my_test = 5; $ans = $my_test * 6);
  
T0_L1:
  ldi(r7, ); 
  ldi(r0, 1);
  mv(r1, r0); inc(r0, 1);
  mv(r2, r0); inc(r0, 1);
  mv(r3, r0); inc(r0, 1);
  mv(r4, r0); inc(r0, 1);
  mv(r5, r0); inc(r0, 1);
  mv(r6, r0); inc(r0, 1);
  st(w, r6, r7[5]); ld(w, r5, r7[5]);
  st(w, r5, r7++1); inc(r5, 1);
  nop(); nop();
  nop(); nop();
  nop(); nop();
  nop(); nop();
  nop(); nop();
  
  clr(r0);
  or(r0, 0xE0000000);
  st(w, r3, r0[2]); ld(w, r2, r0[2]);
  inc(r5, 1); st(w, r5, r0++1);
  dec(r5, 1); ld(w, r4, r0--1);
  
  clr(r0);
  or(r0, 0xE0010000);
  st(w, r3, r0[2]); ld(w, r2, r0[2]);
  inc(r5, 1); st(w, r5, r0++1);
  dec(r5, 1); ld(w, r4, r0--1);
  
  ldi(r0, 0xFFFFE0);
  st(w, r3, r0[2]); ld(w, r2, r0[2]);
  inc(r5, 1); st(w, r5, r0++1);
  dec(r5, 1); ld(w, r4, r0--1);
  
  ldi(r1, 1);
  st(w, r1, r0[6]); nop();
T0_L2:
  br(T0_L2); inc(r0, 1);
  
T1_L1:
  br(T1_L1);
  
  ldi(r7, 0x800); 
  ldi(r0, 3);
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

T2_L1:
T3_L1:
  br(T2_L1);
  
