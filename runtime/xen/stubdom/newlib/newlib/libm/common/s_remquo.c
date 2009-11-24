/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include "fdlibm.h"

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double remquo(double x, double y, int *quo)	/* wrapper remquo */
#else
	double remquo(x,y,quo)			/* wrapper remquo */
	double x,y;
        int *quo;
#endif
{
        int signx, signy, signres;
        int mswx;
        int mswy;
        double x_over_y;

        GET_HIGH_WORD(mswx, x);
        GET_HIGH_WORD(mswy, y);

        signx = (mswx & 0x80000000) >> 31;
        signy = (mswy & 0x80000000) >> 31;

        signres = (signx ^ signy) ? -1 : 1;

        x_over_y = fabs(x / y);

        *quo = signres * (lrint(x_over_y) & 0x7f);

        return remainder(x,y);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
