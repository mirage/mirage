/*
 * __isinff(x) returns 1 if x is +-infinity, else 0;
 * Added by Cygnus Support.
 */

#include "fdlibm.h"

int
_DEFUN (__isinff, (x),
	float x)
{
	__int32_t ix;
	GET_FLOAT_WORD(ix,x);
	ix &= 0x7fffffff;
	return FLT_UWORD_IS_INFINITE(ix);
}

#ifdef _DOUBLE_IS_32BITS

int
_DEFUN (__isinfd, (x),
	double x)
{
	return __isinff((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
