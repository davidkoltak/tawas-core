

  jmp(t0_start);
  jmp(t1_start);

stall_loop:
  jmp(stall_loop);

t0_start:
  ldi(r7, 0xFFFC);
  ldi(r0, 11);
  ldi(r6, 0x120);
  call(nested_call); push(r6);
  pop(r6);
  nop();
  icall(r6); push(r6);
  pop(r6);
  nop();
  call(test_pass);

t1_start:
  ldi(r7, 0xFEFF);
  nop2();
  nop2();
  nop2();
  nop2();
  jmp(stall_loop);
  

.org(0x100);
nested_call:
  dec(r0, 1);
  br(zero, nested_call_rtn);
  call(nested_call); push(r6);
  pop(r6);
  nop2();
nested_call_rtn: 
  rtn();
  jmp(stall_loop);
  
test_pass:
  ldi(r0, -15);
  ldi(r1, 1);
  st(w, r1, r0[2]);
  rtn();

.org(0x120);
test2:
  ldi(r0, 3);
  call(nested_call); push(r6);
  pop(r6);
  nop();
  rtn();
   
