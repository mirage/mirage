#include <stdio.h>

#include "c99ppe.h"

#undef putchar

#ifndef _REENT_ONLY

int
putchar (c)
     int c;
{
  CHECK_STD_INIT(_REENT);

  /* c gets overwritten before return */

  return __send_to_ppe(SPE_C99_SIGNALCODE, SPE_C99_PUTCHAR, &c);
}

#endif /* ! _REENT_ONLY */
