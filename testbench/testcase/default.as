

start:
  jmp(START_0);
  jmp(START_1);
  jmp(START_2);
  jmp(START_3);
  
START_1:
START_2:
START_3:
STALL_LOOP:
  br(STALL_LOOP);
  
#include "lib/string.as"
#include "lib/tests.as"
  
START_0:
  .alloc32(stack_0_bot, 31, 0);
  .data32(stack_0_top, 0xAAAAAAAA);

  .string(test_string, "This is a test");
  
  .alloc8(string_buf, 32, 0xF);
  
  ldi(r7, stack_0_top);
  
  ldi(r0, test_string); 
  ldi(r1, string_buf);
  call(strcpy); 
  cmp(r0, 15);
  br(!equal, test_fail);
  
  ldi(r0, test_string); 
  ldi(r1, string_buf);
  call(strcmp); 
  cmp(r0, 0);
  br(!equal, test_fail);

  br(test_pass);
  
