/* vec_realloc.c -- a wrapper for _vec_realloc_r.  */

#include <_ansi.h>
#include <reent.h>
#include <stdlib.h>

#ifndef _REENT_ONLY

_PTR
_DEFUN (vec_realloc, (ap, nbytes),
	_PTR ap _AND
	size_t nbytes)
{
  return _vec_realloc_r (_REENT, ap, nbytes);
}

#endif
