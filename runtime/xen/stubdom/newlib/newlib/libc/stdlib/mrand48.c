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
_DEFUN (_mrand48_r, (r),
       struct _reent *r)
{
  _REENT_CHECK_RAND48(r);
  __dorand48(r, __rand48_seed);
  return ((long) __rand48_seed[2] << 16) + (long) __rand48_seed[1];
}

#ifndef _REENT_ONLY
long
_DEFUN_VOID (mrand48)
{
  return _mrand48_r (_REENT);
}
#endif /* !_REENT_ONLY */
