
// basic string library

strcpy:
  push(r3); mv(r3, r1);
  ld(b, r2, r0++1);
strcpy_loop:
  or(r2, r2); st(b, r2, r1++1);
  br(!zero, strcpy_loop); ld(b, r2, r0++1);
strcpy_done:
  pop(r3); sub(r0, r1, r3);
  rtn();

strcmp:
  push(r4); push(r3);
  ld(b, r2, r0++1); ld(b, r3, r1++1);
strcmp_loop:
  ld(b, r2, r0++1); sub(r4, r2, r3);
  br(!zero, strcmp_done); or(r3, r3);
  br(!zero, strcmp_loop); ld(b, r3, r1++1);
strcmp_done:
  pop(r3); mv(r0, r4);
  pop(r4); rtn();
