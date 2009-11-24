/*
 * dremf() wrapper for remainderf().
 * 
 * Written by J.T. Conklin, <jtc@wimsey.com>
 * Placed into the Public Domain, 1994.
 */

#include "fdlibm.h"

float
#ifdef __STDC__
dremf(float x, float y)
#else
dremf(x, y)
	float x, y;
#endif
{
	return remainderf(x, y);
}
