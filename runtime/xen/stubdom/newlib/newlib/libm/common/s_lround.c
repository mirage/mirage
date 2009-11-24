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

#include "fdlibm.h"

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	long int lround(double x)
#else
	long int lround(x)
	double x;
#endif
{
  __int32_t sign, exponent_less_1023;
  /* Most significant word, least significant word. */
  __uint32_t msw, lsw;
  long int result;
  
  EXTRACT_WORDS(msw, lsw, x);

  /* Extract sign. */
  sign = ((msw & 0x80000000) ? -1 : 1);
  /* Extract exponent field. */
  exponent_less_1023 = ((msw & 0x7ff00000) >> 20) - 1023;
  msw &= 0x000fffff;
  msw |= 0x00100000;

  if (exponent_less_1023 < 20)
    {
      if (exponent_less_1023 < 0)
        {
          if (exponent_less_1023 < -1)
            return 0;
          else
            return sign;
        }
      else
        {
          msw += 0x80000 >> exponent_less_1023;
          result = msw >> (20 - exponent_less_1023);
        }
    }
  else if (exponent_less_1023 < (8 * sizeof (long int)) - 1)
    {
      if (exponent_less_1023 >= 52)
        result = ((long int) msw << (exponent_less_1023 - 20)) | (lsw << (exponent_less_1023 - 52));
      else
        {
          unsigned int tmp = lsw + (0x80000000 >> (exponent_less_1023 - 20));
          if (tmp < lsw)
            ++msw;
          result = ((long int) msw << (exponent_less_1023 - 20)) | (tmp >> (52 - exponent_less_1023));
        }
    }
  else
    /* Result is too large to be represented by a long int. */
    return (long int)x;

  return sign * result;
}

#endif /* _DOUBLE_IS_32BITS */
