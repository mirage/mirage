/* sf_finite.c -- float version of s_finite.c.
 * Conversion to float by Ian Lance Taylor, Cygnus Support, ian@cygnus.com.
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
 * finitef(x) returns 1 is x is finite, else 0;
 * no branching!
 */

#include "fdlibm.h"

#ifdef __STDC__
	int finitef(float x)
#else
	int finitef(x)
	float x;
#endif
{
	__int32_t ix;
	GET_FLOAT_WORD(ix,x);
	ix &= 0x7fffffff;
	return (FLT_UWORD_IS_FINITE(ix));
}

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	int finite(double x)
#else
	int finite(x)
	double x;
#endif
{
	return finitef((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
