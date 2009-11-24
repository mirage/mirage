/*
 * [atw] multiply 64 bit accumulator by 10 and add digit.
 * The KA/CA way to do this should be to use
 * a 64-bit integer internally and use "adjust" to
 * convert it to float at the end of processing.
 */

#include <_ansi.h>

int
_DEFUN (__ten_mul, (acc, digit),
	double *acc _AND
	int digit)
{
  /*
   * [atw] Crude, but effective (at least on a KB)...
   */

  *acc *= 10;
  *acc += digit;

  return 0;			/* no overflow */
}
