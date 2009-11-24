/*
 * ctime.c
 * Original Author:	G. Haley
 */

/*
FUNCTION
<<ctime>>---convert time to local and format as string

INDEX
	ctime

ANSI_SYNOPSIS
	#include <time.h>
	char *ctime(const time_t *<[clock]>);
	char *ctime_r(const time_t *<[clock]>, char *<[buf]>);

TRAD_SYNOPSIS
	#include <time.h>
	char *ctime(<[clock]>)
	time_t *<[clock]>;

	char *ctime_r(<[clock]>, <[buf]>)
	time_t *<[clock]>;
	char *<[buf]>;

DESCRIPTION
Convert the time value at <[clock]> to local time (like <<localtime>>)
and format it into a string of the form
. Wed Jun 15 11:38:07 1988\n\0
(like <<asctime>>).

RETURNS
A pointer to the string containing a formatted timestamp.

PORTABILITY
ANSI C requires <<ctime>>.

<<ctime>> requires no supporting OS subroutines.
*/

#include <time.h>

#ifndef _REENT_ONLY

char *
_DEFUN (ctime, (tim_p),
	_CONST time_t * tim_p)
{
  return asctime (localtime (tim_p));
}

#endif
