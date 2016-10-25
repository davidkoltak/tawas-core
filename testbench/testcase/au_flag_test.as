
  jmp(t0_start);
  jmp(t1_start);


t0_start:
  ldi(r7, 0xFFFF); 
  ldi(r6, 7);
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
  push(r0); push(r1);
  ldi(r0, -1);
  ldi(r1, -0x6);
  cmp(r0, r1);
  br(zero, zero_test_fail); inc(r1, 5);
  cmp(r0, r1);
  br(!zero, zero_test_fail); inc(r0, 1);
  br(!zero, zero_test_fail); cmp(r0, r1);
  br(zero, zero_test_fail);
  pop(r1); pop(r2);
  rtn();
zero_test_fail:
  ldi(r0, 0xFFFFF0);
  ldi(r1, 1);
  st(w, r1, r0[3]);
  rtn();

test_pass:
  ldi(r0, 0xFFFFF0); 
  ldi(r1, 1);
  st(w, r1, r0[2]);
  rtn();
