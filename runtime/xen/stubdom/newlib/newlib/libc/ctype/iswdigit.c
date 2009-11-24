/*
FUNCTION
	<<iswdigit>>---decimal digit wide character test

INDEX
	iswdigit

ANSI_SYNOPSIS
	#include <wctype.h>
	int iswdigit(wint_t <[c]>);

TRAD_SYNOPSIS
	#include <wctype.h>
	int iswdigit(<[c]>)
	wint_t <[c]>;

DESCRIPTION
<<iswdigit>> is a function which classifies wide-character values that
are decimal digits.

RETURNS
<<iswdigit>> returns non-zero if <[c]> is a decimal digit wide character.

PORTABILITY
<<iswdigit>> is C99.

No supporting OS subroutines are required.
*/
#include <_ansi.h>
#include <wctype.h>

int
_DEFUN(iswdigit,(c), wint_t c)
{
  return (c >= (wint_t)'0' && c <= (wint_t)'9');
}

