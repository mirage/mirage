/*
FUNCTION
<<wcstombs>>---minimal wide char string to multibyte string converter

INDEX
	wcstombs

ANSI_SYNOPSIS
	#include <stdlib.h>
	int wcstombs(const char *<[s]>, wchar_t *<[pwc]>, size_t <[n]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	int wcstombs(<[s]>, <[pwc]>, <[n]>)
	const char *<[s]>;
	wchar_t *<[pwc]>;
	size_t <[n]>;

DESCRIPTION
When _MB_CAPABLE is not defined, this is a minimal ANSI-conforming 
implementation of <<wcstombs>>.  In this case,
all wide-characters are expected to represent single bytes and so
are converted simply by casting to char.

When _MB_CAPABLE is defined, this routine calls <<_wcstombs_r>> to perform
the conversion, passing a state variable to allow state dependent
decoding.  The result is based on the locale setting which may
be restricted to a defined set of locales.

RETURNS
This implementation of <<wcstombs>> returns <<0>> if
<[s]> is <<NULL>> or is the empty string; 
it returns <<-1>> if _MB_CAPABLE and one of the
wide-char characters does not represent a valid multi-byte character;
otherwise it returns the minimum of: <<n>> or the
number of bytes that are transferred to <<s>>, not including the
nul terminator.

If the return value is -1, the state of the <<pwc>> string is
indeterminate.  If the input has a length of 0, the output
string will be modified to contain a wchar_t nul terminator if
<<n>> > 0.

PORTABILITY
<<wcstombs>> is required in the ANSI C standard.  However, the precise
effects vary with the locale.

<<wcstombs>> requires no supporting OS subroutines.
*/

#ifndef _REENT_ONLY

#include <newlib.h>
#include <stdlib.h>
#include <wchar.h>

size_t
_DEFUN (wcstombs, (s, pwcs, n),
        char          *s    _AND
        const wchar_t *pwcs _AND
        size_t         n)
{
#ifdef _MB_CAPABLE
  mbstate_t state;
  state.__count = 0;
  
  return _wcstombs_r (_REENT, s, pwcs, n, &state);
#else /* not _MB_CAPABLE */
  int count = 0;
  
  if (n != 0) {
    do {
      if ((*s++ = (char) *pwcs++) == 0)
	break;
      count++;
    } while (--n != 0);
  }
  
  return count;
#endif /* not _MB_CAPABLE */
}

#endif /* !_REENT_ONLY */
