/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include "fdlibm.h"

#ifdef __STDC__
	float remquof(float x, float y, int *quo)	/* wrapper remquof */
#else
	float remquof(x,y,quo)			/* wrapper remquof */
	float x,y;
        int *quo;
#endif
{
        int signx, signy, signres;
        int wx;
        int wy;
        float x_over_y;

        GET_FLOAT_WORD(wx, x);
        GET_FLOAT_WORD(wy, y);

        signx = (wx & 0x80000000) >> 31;
        signy = (wy & 0x80000000) >> 31;

        signres = (signx ^ signy) ? -1 : 1;

        x_over_y = fabsf(x / y);

        *quo = signres * (lrintf(x_over_y) & 0x7f);

        return remainderf(x,y);
}

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double remquo(double x, double y, int *quo)	/* wrapper remquof */
#else
	double remquo(x,y,quo)			/* wrapper remquof */
	double x,y;
        int *quo;
#endif
{
	return (double) remquof((float) x, (float) y, quo);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
