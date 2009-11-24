/*
 * cabsf() wrapper for hypotf().
 * 
 * Written by J.T. Conklin, <jtc@wimsey.com>
 * Placed into the Public Domain, 1994.
 */

#include "fdlibm.h"

struct complex {
	float x;
	float y;
};

float
cabsf(z)
	struct complex z;
{
	return hypotf(z.x, z.y);
}
