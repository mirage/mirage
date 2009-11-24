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

unsigned short *
_DEFUN (_seed48_r, (r, xseed),
       struct _reent *r _AND
       unsigned short xseed[3])
{
  static unsigned short sseed[3];

  _REENT_CHECK_RAND48(r);
  sseed[0] = __rand48_seed[0];
  sseed[1] = __rand48_seed[1];
  sseed[2] = __rand48_seed[2];
  __rand48_seed[0] = xseed[0];
  __rand48_seed[1] = xseed[1];
  __rand48_seed[2] = xseed[2];
  __rand48_mult[0] = _RAND48_MULT_0;
  __rand48_mult[1] = _RAND48_MULT_1;
  __rand48_mult[2] = _RAND48_MULT_2;
  __rand48_add = _RAND48_ADD;
  return sseed;
}

#ifndef _REENT_ONLY
unsigned short *
_DEFUN (seed48, (xseed),
       unsigned short xseed[3])
{
  return _seed48_r (_REENT, xseed);
}
#endif /* !_REENT_ONLY */
