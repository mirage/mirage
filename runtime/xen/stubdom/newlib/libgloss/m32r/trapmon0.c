/*
 * Mon2000 Trap handler (syscall interface).
 *
 * This trap handler is linked into the mon2000 libgloss (libmon).
 */
#include <reent.h>
#include "syscall.h"

int __trap0 (int function, int p1, int p2, int p3, struct _reent *r)
{
  int rc = 0;

  switch (function) {
  case SYS_exit:
    /* loop so GDB can't go past system exit call */
    while (1) {
      asm volatile (
          "ldi	  r0, #0						\n"
          "trap    #15        ; return control to Mon2000");
    }
    break;

  case SYS_write:
  {
    int i;

    for( i=0; i<p3; i++ ) {
      asm volatile (
          "ldi   r0, #2							\n"
          "ldi   r1, #15      ; load Ctrl-O (ASCII 15)			\n"
          "trap  #15          ; write Ctrl-O for quoting purposes" );

      asm volatile (
          "ldi   r0, #2							\n"
          "ldb   r1, %0							\n"
          "trap  #15          ; write character to console" 
          : /* no outputs */
          : "m" (((char*)p2)[i]));
    }

    rc = p3;                 /* return number of chars written */
    break;
  }

  default:
    rc = 0;
    break;
  }

  return rc;
}


