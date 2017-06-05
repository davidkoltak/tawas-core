
.global test_fail
test_fail:
  mvi r8 -16
  \ mvi r1 1 
  st w r1 r8[3] 
  halt

.global test_pass
test_pass:
  mvi r8 -16
  \ mvi r1 1 
  st w r1 r8[2] 
  halt
