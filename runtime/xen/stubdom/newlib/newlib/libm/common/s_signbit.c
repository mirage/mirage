/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include "fdlibm.h"

int __signbitf (float x);
int __signbitd (double x);

int
__signbitf (float x)
{
  unsigned int w;

  GET_FLOAT_WORD(w,x);

  return (w & 0x80000000);
}

int
__signbitd (double x)
{
  unsigned int msw;

  GET_HIGH_WORD(msw, x);

  return (msw & 0x80000000);
}
