/*
FUNCTION
	<<iswxdigit>>---hexadecimal digit wide character test

INDEX
	iswxdigit

ANSI_SYNOPSIS
	#include <wctype.h>
	int iswxdigit(wint_t <[c]>);

TRAD_SYNOPSIS
	#include <wctype.h>
	int iswxdigit(<[c]>)
	wint_t <[c]>;

DESCRIPTION
<<iswxdigit>> is a function which classifies wide character values that
are hexadecimal digits.

RETURNS
<<iswxdigit>> returns non-zero if <[c]> is a hexadecimal digit wide character.

PORTABILITY
<<iswxdigit>> is C99.

No supporting OS subroutines are required.
*/
#include <_ansi.h>
#include <wctype.h>

int
_DEFUN(iswxdigit,(c), wint_t c)
{
  return ((c >= (wint_t)'0' && c <= (wint_t)'9') ||
	  (c >= (wint_t)'a' && c <= (wint_t)'f') ||
	  (c >= (wint_t)'A' && c <= (wint_t)'F'));
}

