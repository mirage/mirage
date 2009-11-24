
#include <_ansi.h>
#include <stdio.h>

#include "c99ppe.h"

#ifdef _HAVE_STDC
#include <stdarg.h>
#else
#include <varargs.h>
#endif

#ifdef INTEGER_ONLY
#  define vsprintf vsiprintf
#endif

typedef struct
{
  char *str;
  unsigned int pad0[ 3 ];
  char *fmt;
  unsigned int pad1[ 3 ];
  va_list ap;
} c99_vsprintf_t;

#ifndef _REENT_ONLY

int
_DEFUN (vsprintf, (str, fmt, ap),
     char *str _AND
     _CONST char *fmt _AND
     va_list ap)
{
  c99_vsprintf_t args;

  CHECK_STR_INIT(_REENT);

  args.str = str;
  args.fmt = (char*) fmt;
  va_copy(args.ap,ap);

  return __send_to_ppe(SPE_C99_SIGNALCODE, SPE_C99_VSPRINTF, &args);
}

#endif /* ! _REENT_ONLY */
