/* w_gammaf.c -- float version of w_gamma.c.
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

#include "math.h"
#include "fdlibm.h"

#ifdef __STDC__
	float tgammaf(float x)
#else
	float tgammaf(x)
	float x;
#endif
{
        float y;
	int local_signgam;
	y = __ieee754_gammaf_r(x,&local_signgam);
	if (local_signgam < 0) y = -y;
#ifdef _IEEE_LIBM
	return y;
#else
	if(_LIB_VERSION == _IEEE_) return y;

	if(!finitef(y)&&finitef(x)) {
	  if(floorf(x)==x&&x<=(float)0.0)
	    /* tgammaf pole */
	    return (float)__kernel_standard((double)x,(double)x,141);
	  else
	    /* tgammaf overflow */
	    return (float)__kernel_standard((double)x,(double)x,140);
	}
	return y;
#endif
}
