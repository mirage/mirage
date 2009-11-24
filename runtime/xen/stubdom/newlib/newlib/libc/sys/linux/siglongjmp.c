/* libc/sys/linux/siglongjmp.c - siglongjmp function */

/* Copyright 2002, Red Hat Inc. */


#include <setjmp.h>
#include <signal.h>
#include <machine/weakalias.h>

void
__libc_siglongjmp (sigjmp_buf env, int val)
{
  if (env.__is_mask_saved)
    sigprocmask (SIG_SETMASK, &env.__saved_mask, NULL);

  __libc_longjmp (env.__buf, val);
}
weak_alias(__libc_siglongjmp,siglongjmp);
