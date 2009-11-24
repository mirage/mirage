
/*
FUNCTION
	<<iswlower>>---lowercase wide character test

INDEX
	iswlower

ANSI_SYNOPSIS
	#include <wctype.h>
	int iswlower(wint_t <[c]>);

TRAD_SYNOPSIS
	#include <wctype.h>
	int iswlower(<[c]>)
	wint_t <[c]>;

DESCRIPTION
<<iswlower>> is a function which classifies wide-character values that
have uppercase translations.

RETURNS
<<iswlower>> returns non-zero if <[c]> is a lowercase wide character.

PORTABILITY
<<iswlower>> is C99.

No supporting OS subroutines are required.
*/
#include <_ansi.h>
#include <wctype.h>

int
_DEFUN(iswlower,(c),wint_t c)
{
	return (towupper (c) != c);
}

