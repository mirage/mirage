/*
 * Jeff Johnston - 02/13/2002
 */

#ifdef __SPE__

#include <stdlib.h>
#include <_ansi.h>

__uint64_t
_DEFUN (_atoufix64_r, (reent, s),
	struct _reent *reent _AND
	_CONST char *s)
{
  return _strtoufix64_r (reent, s, NULL);
}

#ifndef _REENT_ONLY
__uint64_t
_DEFUN (atoufix64, (s),
	_CONST char *s)
{
  return strtoufix64 (s, NULL);
}

#endif /* !_REENT_ONLY */

#endif /* __SPE__ */
