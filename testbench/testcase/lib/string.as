
// basic string library

strcpy:
  push(r4); clr(r4);
  push(r3); clr(r3);
  ld(b, r2, r0++1);
strcpy_loop:
  cmp(r2, r3); st(b, r2, r1++1);
  br(equal, strcpy_done); inc(r4, 1);
  br(strcpy_loop); ld(b, r2, r0++1);
strcpy_done:
  pop(r3); mv(r0, r4);
  pop(r4); rtn();

strcmp:
  push(r4); push(r3);
  ld(b, r2, r0++1); ld(b, r3, r1++1);
strcmp_loop:
  ld(b, r2, r0++1); sub(r4, r2, r3);
  br(!zero, strcmp_done); cmp(r4, r3);
  br(!equal, strcmp_loop); ld(b, r3, r1++1);
strcmp_done:
  pop(r3); mv(r0, r4);
  pop(r4); rtn();
