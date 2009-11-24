/*
FUNCTION
	<<iswctype>>---extensible wide-character test

INDEX
	iswctype

ANSI_SYNOPSIS
	#include <wctype.h>
	int iswctype(wint_t <[c]>, wctype_t <[desc]>);

TRAD_SYNOPSIS
	#include <wctype.h>
	int iswctype(<[c]>, <[desc]>)
	wint_t <[c]>;
	wctype_t <[desc]>;

DESCRIPTION
<<iswctype>> is a function which classifies wide-character values using the
wide-character test specified by <[desc]>.

RETURNS
<<iswctype>> returns non-zero if and only if <[c]> matches the test specified by <[desc]>.
If <[desc]> is unknown, zero is returned.

PORTABILITY
<<iswctype>> is C99.

No supporting OS subroutines are required.
*/
#include <_ansi.h>
#include <wctype.h>
#include "local.h"

int
_DEFUN(iswctype,(c, desc), wint_t c _AND wctype_t desc)
{
  switch (desc)
    {
    case WC_ALNUM:
      return iswalnum (c);
    case WC_ALPHA:
      return iswalpha (c);
    case WC_BLANK:
      return iswblank (c);
    case WC_CNTRL:
      return iswcntrl (c);
    case WC_DIGIT:
      return iswdigit (c);
    case WC_GRAPH:
      return iswgraph (c);
    case WC_LOWER:
      return iswlower (c);
    case WC_PRINT:
      return iswprint (c);
    case WC_PUNCT:
      return iswpunct (c);
    case WC_SPACE:
      return iswspace (c);
    case WC_UPPER:
      return iswupper (c);
    case WC_XDIGIT:
      return iswxdigit (c);
    default:
      return 0; /* eliminate warning */
    }

  /* otherwise unknown */
  return 0;
}

