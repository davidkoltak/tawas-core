

_t1_reset:
_t2_reset:
_t3_reset:
STALL_LOOP:
  br STALL_LOOP 
  
_t0_reset:
  .alloc32 stack_0_bot 31
  .data32 stack_0_top 0xAAAAAAAA 
  .string test_string "This is a test" 
  .alloc8 string_buf 32
  
  ldi r15 stack_0_top 
  
  ldi r8 test_string  
  ldi r9 string_buf 
  call strcpy  
  cmpi r0 15 
  skip eq
  call test_fail 
  
  ldi r8 test_string  
  ldi r9 string_buf 
  call strcmp  
  cmpi r0 0
  skip eq
  call test_fail 

  ldi r8 test_string  
  ldi r9 string_buf 
  mvi r2 0x30 
  st b r2 r9[2] 
  call strcmp  
  cmpi r0 0
  skip ne
  call test_fail 

  call test_pass 
  
