/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include "fdlibm.h"

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double fmax(double x, double y)
#else
	double fmax(x,y)
	double x;
	double y;
#endif
{
  if (__fpclassifyd(x) == FP_NAN)
    return y;
  if (__fpclassifyd(y) == FP_NAN)
    return x;
  
  return x > y ? x : y;
}

#endif /* _DOUBLE_IS_32BITS */
