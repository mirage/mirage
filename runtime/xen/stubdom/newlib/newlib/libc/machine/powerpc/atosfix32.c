/*
 * Jeff Johnston - 02/13/2002
 */

#ifdef __SPE__

#include <stdlib.h>
#include <_ansi.h>

__int32_t
_DEFUN (_atosfix32_r, (reent, s),
	struct _reent *reent _AND
	_CONST char *s)
{
  return _strtosfix32_r (reent, s, NULL);
}

#ifndef _REENT_ONLY
__int32_t
_DEFUN (atosfix32, (s),
	_CONST char *s)
{
  return strtosfix32 (s, NULL);
}

#endif /* !_REENT_ONLY */

#endif /* __SPE__ */
