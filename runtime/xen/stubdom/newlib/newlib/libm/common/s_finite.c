
/* @(#)s_finite.c 5.1 93/09/24 */
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
 * finite(x) returns 1 is x is finite, else 0;
 * no branching!
 */

#include "fdlibm.h"

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	int finite(double x)
#else
	int finite(x)
	double x;
#endif
{
	__int32_t hx;
	GET_HIGH_WORD(hx,x);
	return  (int)((__uint32_t)((hx&0x7fffffff)-0x7ff00000)>>31);
}

#endif /* _DOUBLE_IS_32BITS */
