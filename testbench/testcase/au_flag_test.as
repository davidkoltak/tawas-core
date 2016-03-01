
  jmp(t0_start);
  jmp(t1_start);


t0_start:
  mv(r6, 0xFFFF); inc(r7, 7);
  call(zero_test); push(r7);
  st(w, r7, r0[9]); nop();
  call(test_pass);
  call(stall_loop);

t1_start:
  mv(r6, 0xFEFF); nop();
  nop(); nop();
  nop(); nop();
  nop(); nop();
  nop(); nop();
  call(stall_loop);
  
stall_loop:
  jmp(stall_loop);
  
zero_test:
  push(r0); mv(r0, -1);
  push(r1); mv(r1, -0x6);
  cmp(r0, r1); nop();
  br(zero, zero_test_fail); inc(r1, 5);
  cmp(r0, r1); nop(); 
  br(!zero, zero_test_fail); inc(r0, 1);
  br(!zero, zero_test_fail); cmp(r0, r1);
  br(zero, zero_test_fail); nop();
  pop(r1); pop(r2);
  rtn(); pop(r7);
zero_test_fail:
  mv(r0, 0xFFFFFFF0); nop();
  mv(r1, 1); nop();
  st(w, r1, r0[3]); nop();
  rtn(); pop(r7);

test_pass:
  mv(r0, 0xFFFFFFF0); clr(r1);
  st(w, r1, r0[2]); nop();
  rtn();
