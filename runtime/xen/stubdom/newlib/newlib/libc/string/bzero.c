/*
FUNCTION
<<bzero>>---initialize memory to zero

INDEX
	bzero

ANSI_SYNOPSIS
	#include <string.h>
	void bzero(void *<[b]>, size_t <[length]>);

TRAD_SYNOPSIS
	#include <string.h>
	void bzero(<[b]>, <[length]>)
	void *<[b]>;
	size_t <[length]>;

DESCRIPTION
<<bzero>> initializes <[length]> bytes of memory, starting at address
<[b]>, to zero.

RETURNS
<<bzero>> does not return a result.

PORTABILITY
<<bzero>> is in the Berkeley Software Distribution.
Neither ANSI C nor the System V Interface Definition (Issue 2) require
<<bzero>>.

<<bzero>> requires no supporting OS subroutines.
*/

#include <string.h>

_VOID
_DEFUN (bzero, (b, length),
	void *b _AND
	size_t length)
{
  char *ptr = (char *)b;
  while (length--)
    *ptr++ = 0;
}
