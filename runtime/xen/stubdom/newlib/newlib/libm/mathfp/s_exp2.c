/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include "fdlibm.h"

#ifndef _DOUBLE_IS_32BITS

double
_DEFUN (exp2, (double),
        double x)
{
  return pow(2.0, x);
}

#endif /* _DOUBLE_IS_32BITS */
