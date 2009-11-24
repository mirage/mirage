/*
 * nanf () returns a nan.
 * Added by Cygnus Support.
 */

#include "fdlibm.h"

	float nanf(const char *unused)
{
	float x;

	SET_FLOAT_WORD(x,0x7fc00000);
	return x;
}

#ifdef _DOUBLE_IS_32BITS

	double nan(const char *arg)
{
	return (double) nanf(arg);
}

#endif /* defined(_DOUBLE_IS_32BITS) */

