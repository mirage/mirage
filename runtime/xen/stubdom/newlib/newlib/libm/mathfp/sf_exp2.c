/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include "fdlibm.h"

float
_DEFUN (exp2f, (float),
        float x)
{
  return powf(2.0, x);
}

#ifdef _DOUBLE_IS_32BITS

double exp2 (double x)
{
  return (double) exp2f ((float) x);
}

#endif /* _DOUBLE_IS_32BITS */
