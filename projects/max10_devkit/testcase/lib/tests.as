
test_fail:
  mvi(r0, -16); mvi(r1, 1);
  st(w, r1, r0[3]);
test_fail_stop:
  br(test_fail_stop);

test_pass:
  mvi(r0, -16); mvi(r1, 1);
  st(w, r1, r0[2]);
test_pass_stop:
  br(test_pass_stop);
