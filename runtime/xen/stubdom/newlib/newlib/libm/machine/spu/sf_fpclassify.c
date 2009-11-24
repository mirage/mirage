/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include "fdlibm.h"

/*
 * On the SPU, single precision floating point returns only FP_NORMAL and
 * FP_ZERO, since FP_NAN, FP_INFINITE, and FP_SUBNORMAL are not
 * supported, base on the common f_fpclassify.c.
 */
int
__fpclassifyf (float x)
{
  __uint32_t w;

  GET_FLOAT_WORD(w,x);

  if (w == 0x00000000 || w == 0x80000000)
    return FP_ZERO;
  return FP_NORMAL;
}
