#include <stdio.h>
#include <errno.h>

#include "c99ppe.h"

#ifndef _REENT_ONLY

typedef struct
{
  _CONST char* str;
  unsigned int pad0[ 3 ];
  int arg_errno;
  unsigned int pad1[ 3 ];
} c99_perror_t;

void
_DEFUN (perror, (s),
	_CONST char *s)

{
  c99_perror_t arg;

  CHECK_STD_INIT(_REENT);

  arg.str = s;
  arg.arg_errno = errno;
  __send_to_ppe(SPE_C99_SIGNALCODE, SPE_C99_PERROR, &arg);

  return;
}
#endif /* ! _REENT_ONLY */
