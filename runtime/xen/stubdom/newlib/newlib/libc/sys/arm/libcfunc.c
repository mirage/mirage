/* Support files for GNU libc.  Files in the C namespace go here.
   Files in the system namespace (ie those that start with an underscore)
   go in syscalls.c.
   
   Note: These functions are in a seperate file so that OS providers can
   overrride the system call stubs (defined in syscalls.c) without having
   to provide libc funcitons as well.  */
#include "swi.h"

#ifdef ARM_RDI_MONITOR

static inline int
do_AngelSWI (int reason, void * arg)
{
  int value;
  asm volatile ("mov r0, %1; mov r1, %2; " AngelSWIInsn " %a3; mov %0, r0"
       : "=r" (value) /* Outputs */
       : "r" (reason), "r" (arg), "i" (AngelSWI) /* Inputs */
       : "r0", "r1", "lr"
		/* Clobbers r0 and r1, and lr if in supervisor mode */);
  return value;
}
#endif /* ARM_RDI_MONITOR */


void
alarm (void)
{
}
