
/* @(#)z_pow.c 1.0 98/08/13 */

/*
FUNCTION
        <<pow>>, <<powf>>---x to the power y
INDEX
        pow
INDEX
        powf


ANSI_SYNOPSIS
        #include <math.h>
        double pow(double <[x]>, double <[y]>);
        float pow(float <[x]>, float <[y]>);

TRAD_SYNOPSIS
        #include <math.h>
        double pow(<[x]>, <[y]>);
        double <[x]>, <[y]>;

        float pow(<[x]>, <[y]>);
        float <[x]>, <[y]>;

DESCRIPTION
        <<pow>> and <<powf>> calculate <[x]> raised to the exponent <[y]>.
        @tex
        (That is, $x^y$.)
        @end tex

RETURNS
        On success, <<pow>> and <<powf>> return the value calculated.

        When the argument values would produce overflow, <<pow>>
        returns <<HUGE_VAL>> and set <<errno>> to <<ERANGE>>.  If the
        argument <[x]> passed to <<pow>> or <<powf>> is a negative
        noninteger, and <[y]> is also not an integer, then <<errno>>
        is set to <<EDOM>>.  If <[x]> and <[y]> are both 0, then
        <<pow>> and <<powf>> return <<1>>.

        You can modify error handling for these functions using <<matherr>>.

PORTABILITY
        <<pow>> is ANSI C. <<powf>> is an extension.  */

#include <float.h>
#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

double pow (double x, double y)
{
  double d, k, t, r = 1.0;
  int n, sign, exponent_is_even_int = 0;
  __uint32_t px;

  GET_HIGH_WORD (px, x);

  k = modf (y, &d);

  if (k == 0.0)
    {
      /* Exponent y is an integer. */
      if (modf (ldexp (y, -1), &t))
        {
          /* y is odd. */
          exponent_is_even_int = 0;
        }
      else
        {
          /* y is even. */
          exponent_is_even_int = 1;
        }
    }

  if (x == 0.0)
    {
      if (y <= 0.0)
        errno = EDOM;
    }
  else if ((t = y * log (fabs (x))) >= BIGX) 
    {
      errno = ERANGE;
      if (px & 0x80000000) 
        {
          /* x is negative. */
          if (k) 
            {
              /* y is not an integer. */
              errno = EDOM;
              x = 0.0;
            }
          else if (exponent_is_even_int)
            x = z_infinity.d;
          else
            x = -z_infinity.d;
        }
      else
        {
          x = z_infinity.d;
        }
    }
  else if (t < SMALLX)
    {
      errno = ERANGE;
      x = 0.0;
    }
  else 
    {
      if ( !k && fabs(d) <= 32767 ) 
        {
          n = (int) d;

          if ((sign = (n < 0)))
            n = -n;

          while ( n > 0 ) 
            {
              if ((unsigned int) n % 2) 
                r *= x;
              x *= x;
              n = (unsigned int) n / 2;
            }

          if (sign)
            r = 1.0 / r;

          return r;
        }
      else 
        {
          if ( px & 0x80000000 ) 
            {
              /* x is negative. */
              if ( k ) 
                {
                  /* y is not an integer. */
                  errno = EDOM;
                  return 0.0;
                }
            }

          x = exp (t);

          if (!exponent_is_even_int)
            {
              if (px & 0x80000000)
                {
                  /* y is an odd integer, and x is negative,
                     so the result is negative. */
                  GET_HIGH_WORD (px, x);
                  px |= 0x80000000;
                  SET_HIGH_WORD (x, px);
                }
            }
        }
    }

  return x;
}

#endif _DOUBLE_IS_32BITS
