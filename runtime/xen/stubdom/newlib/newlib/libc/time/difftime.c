/*
 * difftime.c
 * Original Author:	G. Haley
 */

/*
FUNCTION
<<difftime>>---subtract two times

INDEX
	difftime

ANSI_SYNOPSIS
	#include <time.h>
	double difftime(time_t <[tim1]>, time_t <[tim2]>);

TRAD_SYNOPSIS
	#include <time.h>
	double difftime(<[tim1]>, <[tim2]>)
	time_t <[tim1]>;
	time_t <[tim2]>;

DESCRIPTION
Subtracts the two times in the arguments: `<<<[tim1]> - <[tim2]>>>'.

RETURNS
The difference (in seconds) between <[tim2]> and <[tim1]>, as a <<double>>.

PORTABILITY
ANSI C requires <<difftime>>, and defines its result to be in seconds
in all implementations.

<<difftime>> requires no supporting OS subroutines.
*/

#include <time.h>

double
_DEFUN (difftime, (tim1, tim2),
	time_t tim1 _AND
	time_t tim2)
{
  return (double)(tim1 - tim2);
}
