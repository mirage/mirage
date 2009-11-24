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

_VOID
_DEFUN (_srand48_r, (r, seed),
       struct _reent *r _AND
       long seed)
{
  _REENT_CHECK_RAND48(r);
  __rand48_seed[0] = _RAND48_SEED_0;
  __rand48_seed[1] = (unsigned short) seed;
  __rand48_seed[2] = (unsigned short) ((unsigned long)seed >> 16);
  __rand48_mult[0] = _RAND48_MULT_0;
  __rand48_mult[1] = _RAND48_MULT_1;
  __rand48_mult[2] = _RAND48_MULT_2;
  __rand48_add = _RAND48_ADD;
}

#ifndef _REENT_ONLY
_VOID
_DEFUN (srand48, (seed),
       long seed)
{
  _srand48_r (_REENT, seed);
}
#endif /* !_REENT_ONLY */
