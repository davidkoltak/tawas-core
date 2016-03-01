

  jmp(t0_start);
  jmp(t1_start);

stall_loop:
  jmp(stall_loop);

t0_start:
  mv(r6, 0xFFFC); inc(r0, 8);
  call(nested_call); push(r7);
  call(test_pass);

t1_start:
  mv(r6, 0xFEFF); nop();
  nop(); nop();
  nop(); nop();
  nop(); nop();
  nop(); nop();
  call(stall_loop);
  

nested_call:
  dec(r0, 1); nop();
  br(zero, nested_call_rtn); nop();
  call(nested_call); push(r7);
  nop(); nop();
nested_call_rtn:
  rtn(); pop(r7);
  
test_pass:
  mv(r0, 0xFFFFFFF0); clr(r1);
  st(w, r1, r0[2]); nop();
  rtn();
  
