/*
FUNCTION
	<<iswalnum>>---alphanumeric wide character test

INDEX
	iswalnum

ANSI_SYNOPSIS
	#include <wctype.h>
	int iswalnum(wint_t <[c]>);

TRAD_SYNOPSIS
	#include <wctype.h>
	int iswalnum(<[c]>)
	wint_t <[c]>;

DESCRIPTION
<<iswalnum>> is a function which classifies wide-character values that
are alphanumeric.

RETURNS
<<iswalnum>> returns non-zero if <[c]> is a alphanumeric wide character.

PORTABILITY
<<iswalnum>> is C99.

No supporting OS subroutines are required.
*/
#include <_ansi.h>
#include <wctype.h>

int
_DEFUN(iswalnum,(c),wint_t c)
{
  return (iswalpha (c) || iswdigit (c));
}

