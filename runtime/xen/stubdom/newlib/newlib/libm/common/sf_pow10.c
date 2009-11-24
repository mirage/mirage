/* sf_pow10.c -- float version of s_pow10.c.
 * Modification of sf_pow10.c by Yaakov Selkowitz 2007.
 */

/*
 * ====================================================
 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 *
 * Developed at SunPro, a Sun Microsystems, Inc. business.
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice 
 * is preserved.
 * ====================================================
 */

/* 
 * wrapper pow10f(x)
 */

#undef pow10f
#include "fdlibm.h"
#include <errno.h>
#include <math.h>

#ifdef __STDC__
	float pow10f(float x)		/* wrapper pow10f */
#else
	float pow10f(x)			/* wrapper pow10f */
	float x;
#endif
{
  return powf(10.0, x);
}

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double pow10(double x)
#else
	double pow10(x)
	double x;
#endif
{
	return (double) pow10f((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
