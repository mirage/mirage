/* sf_exp10.c -- float version of s_exp10.c.
 * Modification of sf_exp2.c by Yaakov Selkowitz 2007.
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
 * wrapper exp10f(x)
 */

#undef exp10f
#include "fdlibm.h"
#include <errno.h>
#include <math.h>

#ifdef __STDC__
	float exp10f(float x)		/* wrapper exp10f */
#else
	float exp10f(x)			/* wrapper exp10f */
	float x;
#endif
{
  return powf(10.0, x);
}

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double exp10(double x)
#else
	double exp10(x)
	double x;
#endif
{
	return (double) exp10f((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
