/*
 * compute 10**x by successive squaring.
 */

#include <_ansi.h>

double
_DEFUN (__exp10, (x),
	unsigned x)
{
  static _CONST double powtab[] =
  {1.0,
   10.0,
   100.0,
   1000.0,
   10000.0};

  if (x < (sizeof (powtab) / sizeof (double)))
      return powtab[x];
  else if (x & 1)
    {
      return 10.0 * __exp10 (x - 1);
    }
  else
    {
      double n = __exp10 (x / 2);
      return n * n;
    }
}
