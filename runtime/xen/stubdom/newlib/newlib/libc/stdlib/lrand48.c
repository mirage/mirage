/*
 * Copyright (c) 1993 Martin Birgmeier
 * All rights reserved.
 *
 * You may redistribute unmodified or modified versions of this source
 * code provided that the above copyright notice and this and the
 * following conditions are retained.
 *
 * This software is provided ``as is'', and comes with no warranties
 * of any kind. I shall in no event be liable for anything that happens
 * to anyone/anything when using this software.
 */

#include "rand48.h"

long
_DEFUN (_lrand48_r, (r),
       struct _reent *r)
{
  _REENT_CHECK_RAND48(r);
  __dorand48(r, __rand48_seed);
  return (long)((unsigned long) __rand48_seed[2] << 15) +
    ((unsigned long) __rand48_seed[1] >> 1);
}

#ifndef _REENT_ONLY
long
_DEFUN_VOID (lrand48)
{
  return _lrand48_r (_REENT);
}
#endif /* !_REENT_ONLY */
