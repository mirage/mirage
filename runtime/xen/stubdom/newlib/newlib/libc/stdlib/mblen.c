/*
FUNCTION
<<mblen>>---minimal multibyte length function

INDEX
	mblen

ANSI_SYNOPSIS
	#include <stdlib.h>
	int mblen(const char *<[s]>, size_t <[n]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	int mblen(<[s]>, <[n]>)
	const char *<[s]>;
	size_t <[n]>;

DESCRIPTION
When _MB_CAPABLE is not defined, this is a minimal ANSI-conforming 
implementation of <<mblen>>.  In this case, the
only ``multi-byte character sequences'' recognized are single bytes,
and thus <<1>> is returned unless <[s]> is the null pointer or
has a length of 0 or is the empty string.

When _MB_CAPABLE is defined, this routine calls <<_mbtowc_r>> to perform
the conversion, passing a state variable to allow state dependent
decoding.  The result is based on the locale setting which may
be restricted to a defined set of locales.

RETURNS
This implementation of <<mblen>> returns <<0>> if
<[s]> is <<NULL>> or the empty string; it returns <<1>> if not _MB_CAPABLE or
the character is a single-byte character; it returns <<-1>>
if the multi-byte character is invalid; otherwise it returns
the number of bytes in the multibyte character.

PORTABILITY
<<mblen>> is required in the ANSI C standard.  However, the precise
effects vary with the locale.

<<mblen>> requires no supporting OS subroutines.
*/

#ifndef _REENT_ONLY

#include <newlib.h>
#include <stdlib.h>
#include <wchar.h>

int
_DEFUN (mblen, (s, n), 
        const char *s _AND
        size_t n)
{
#ifdef _MB_CAPABLE
  int retval = 0;
  mbstate_t *state;
  
  _REENT_CHECK_MISC(_REENT);
  state = &(_REENT_MBLEN_STATE(_REENT));
  retval = _mbtowc_r (_REENT, NULL, s, n, state);
  if (retval < 0)
    {
      state->__count = 0;
      return -1;
    }
  else
    return retval;
  
#else /* not _MB_CAPABLE */
  if (s == NULL || *s == '\0')
    return 0;
  if (n == 0)
    return -1;
  return 1;
#endif /* not _MB_CAPABLE */
}

#endif /* !_REENT_ONLY */
