#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


static void _do_dtors()
{
  /* The loop variable is static so that if a destructor calls exit, 
     and we return here, we simply continue with the next destructor. */
  typedef void (*pfunc) ();
  extern pfunc __dtors[];
  extern pfunc __dtors_end[];
  static pfunc *p = __dtors;
  
  while (p < __dtors_end)
    (*p++) ();
}


void _exit (n)
{
  extern unsigned char __eh_frame_begin[];
  extern void __deregister_frame_info (void *);

  /* Destructors should be done earlier because they need to be done before the
     files are closed, but here is better than nowhere (and this balances the
     constructors done in crt1.c. */
  _do_dtors();

  /* Deregister any eh frames.  */
  __deregister_frame_info (__eh_frame_begin);

  TRAP0 (SYS_exit, n, 0, 0);
}
