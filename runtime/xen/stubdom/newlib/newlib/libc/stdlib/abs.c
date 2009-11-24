/*
FUNCTION
<<abs>>---integer absolute value (magnitude)

INDEX
	abs

ANSI_SYNOPSIS
	#include <stdlib.h>
	int abs(int <[i]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	int abs(<[i]>)
	int <[i]>;

DESCRIPTION
<<abs>> returns
@tex
$|x|$,
@end tex
the absolute value of <[i]> (also called the magnitude
of <[i]>).  That is, if <[i]> is negative, the result is the opposite
of <[i]>, but if <[i]> is nonnegative the result is <[i]>.

The similar function <<labs>> uses and returns <<long>> rather than <<int>> values.

RETURNS
The result is a nonnegative integer.

PORTABILITY
<<abs>> is ANSI.

No supporting OS subroutines are required.
*/

#include <stdlib.h>

int
_DEFUN (abs, (i), int i)
{
  return (i < 0) ? -i : i;
}
