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
_DEFUN (_lcong48_r, (r, p),
       struct _reent *r _AND
       unsigned short p[7])
{
  _REENT_CHECK_RAND48(r);
  __rand48_seed[0] = p[0];
  __rand48_seed[1] = p[1];
  __rand48_seed[2] = p[2];
  __rand48_mult[0] = p[3];
  __rand48_mult[1] = p[4];
  __rand48_mult[2] = p[5];
  __rand48_add = p[6];
}

#ifndef _REENT_ONLY
_VOID
_DEFUN (lcong48, (p),
       unsigned short p[7])
{
  _lcong48_r (_REENT, p);
}
#endif /* !_REENT_ONLY */
