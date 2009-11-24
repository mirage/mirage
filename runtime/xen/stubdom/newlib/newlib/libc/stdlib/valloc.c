#ifndef MALLOC_PROVIDED
/* valloc.c -- a wrapper for valloc_r and pvalloc_r.  */

#include <_ansi.h>
#include <reent.h>
#include <stdlib.h>
#include <malloc.h>

#ifndef _REENT_ONLY

_PTR
_DEFUN (valloc, (nbytes),
	size_t nbytes)
{
  return _valloc_r (_REENT, nbytes);
}

_PTR
_DEFUN (pvalloc, (nbytes),
	size_t nbytes)
{
  return _pvalloc_r (_REENT, nbytes);
}

#endif
#endif
