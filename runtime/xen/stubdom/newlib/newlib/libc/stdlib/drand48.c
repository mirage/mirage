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

double
_DEFUN (_drand48_r, (r),
       struct _reent *r)
{
  _REENT_CHECK_RAND48(r);
  return _erand48_r(r, __rand48_seed);
}

#ifndef _REENT_ONLY
double
_DEFUN_VOID (drand48)
{
  return _drand48_r (_REENT);
}
#endif /* !_REENT_ONLY */
