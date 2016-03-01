
  jmp(t0_start);
  jmp(t1_start);


t0_start:
  mv(r7, 0xFFFF); inc(r6, 7);
  call(zero_test);
  call(test_pass);
  call(stall_loop);

t1_start:
  ldi(r7, 0xFEFF);
  nop2();
  nop2();
  nop2();
  nop2();
  call(stall_loop);
  
stall_loop:
  jmp(stall_loop);
  
zero_test:
  push(r0); mv(r0, -1);
  push(r1); mv(r1, -0x6);
  cmp(r0, r1);
  br(zero, zero_test_fail); inc(r1, 5);
  cmp(r0, r1);
  br(!zero, zero_test_fail); inc(r0, 1);
  br(!zero, zero_test_fail); cmp(r0, r1);
  br(zero, zero_test_fail);
  pop(r1); pop(r2);
  rtn();
zero_test_fail:
  mv(r0, 0xFFFFFFF0);
  mv(r1, 1);
  st(w, r1, r0[3]);
  rtn();

test_pass:
  mv(r0, 0xFFFFFFF0); clr(r1);
  st(w, r1, r0[2]);
  rtn();
