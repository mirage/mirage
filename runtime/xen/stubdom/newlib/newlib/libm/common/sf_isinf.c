/*
 * isinff(x) returns 1 if x is +-infinity, else 0;
 *
 * isinff is an extension declared in <ieeefp.h> and
 * <math.h>.
 */

#include "fdlibm.h"

int
_DEFUN (isinff, (x),
	float x)
{
	__int32_t ix;
	GET_FLOAT_WORD(ix,x);
	ix &= 0x7fffffff;
	return FLT_UWORD_IS_INFINITE(ix);
}

#ifdef _DOUBLE_IS_32BITS

#undef isinf

int
_DEFUN (isinf, (x),
	double x)
{
	return isinff((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
