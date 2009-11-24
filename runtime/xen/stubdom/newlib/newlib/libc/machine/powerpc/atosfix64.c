/*
 * Jeff Johnston - 02/13/2002
 */

#ifdef __SPE__ 

#include <stdlib.h>
#include <_ansi.h>

__int64_t
_DEFUN (_atosfix64_r, (reent, s),
	struct _reent *reent _AND
	_CONST char *s)
{
  return _strtosfix64_r (reent, s, NULL);
}

#ifndef _REENT_ONLY
__int64_t
_DEFUN (atosfix64, (s),
	_CONST char *s)
{
  return strtosfix64 (s, NULL);
}

#endif /* !_REENT_ONLY */

#endif /* __SPE__ */
