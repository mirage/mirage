/*
FUNCTION
<<mbtowc>>---minimal multibyte to wide char converter

INDEX
	mbtowc

ANSI_SYNOPSIS
	#include <stdlib.h>
	int mbtowc(wchar_t *<[pwc]>, const char *<[s]>, size_t <[n]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	int mbtowc(<[pwc]>, <[s]>, <[n]>)
	wchar_t *<[pwc]>;
	const char *<[s]>;
	size_t <[n]>;

DESCRIPTION
When _MB_CAPABLE is not defined, this is a minimal ANSI-conforming 
implementation of <<mbtowc>>.  In this case,
only ``multi-byte character sequences'' recognized are single bytes,
and they are ``converted'' to themselves.
Each call to <<mbtowc>> copies one character from <<*<[s]>>> to
<<*<[pwc]>>>, unless <[s]> is a null pointer.  The argument n
is ignored.

When _MB_CAPABLE is defined, this routine calls <<_mbtowc_r>> to perform
the conversion, passing a state variable to allow state dependent
decoding.  The result is based on the locale setting which may
be restricted to a defined set of locales.

RETURNS
This implementation of <<mbtowc>> returns <<0>> if
<[s]> is <<NULL>> or is the empty string; 
it returns <<1>> if not _MB_CAPABLE or
the character is a single-byte character; it returns <<-1>>
if n is <<0>> or the multi-byte character is invalid; 
otherwise it returns the number of bytes in the multibyte character.
If the return value is -1, no changes are made to the <<pwc>>
output string.  If the input is the empty string, a wchar_t nul
is placed in the output string and 0 is returned.  If the input
has a length of 0, no changes are made to the <<pwc>> output string.

PORTABILITY
<<mbtowc>> is required in the ANSI C standard.  However, the precise
effects vary with the locale.

<<mbtowc>> requires no supporting OS subroutines.
*/

#ifndef _REENT_ONLY

#include <newlib.h>
#include <stdlib.h>
#include <wchar.h>

int
_DEFUN (mbtowc, (pwc, s, n),
        wchar_t *pwc _AND
        const char *s _AND
        size_t n)
{
#ifdef _MB_CAPABLE
  int retval = 0;
  mbstate_t *ps;

  _REENT_CHECK_MISC(_REENT);
  ps = &(_REENT_MBTOWC_STATE(_REENT));
  
  retval = _mbtowc_r (_REENT, pwc, s, n, ps);
  
  if (retval < 0)
    {
      ps->__count = 0;
      return -1;
    }
  return retval;
#else /* not _MB_CAPABLE */
  if (s == NULL)
    return 0;
  if (n == 0)
    return -1;
  if (pwc)
    *pwc = (wchar_t) *s;
  return (*s != '\0');
#endif /* not _MB_CAPABLE */
}

#endif /* !_REENT_ONLY */




