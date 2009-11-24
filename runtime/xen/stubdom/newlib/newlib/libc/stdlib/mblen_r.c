/*
FUNCTION
<<_mblen_r>>---reentrant minimal multibyte length function

INDEX
	_mblen_r

ANSI_SYNOPSIS
	#include <stdlib.h>
	int _mblen_r(struct _reent *<[r]>, const char *<[s]>, size_t <[n]>, int *<[state]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	int _mblen_r(<[r]>, <[s]>, <[n]>, <[state]>)
        struct _reent *<[r]>;
	const char *<[s]>;
	size_t <[n]>;
        int *<[state]>;

DESCRIPTION
When _MB_CAPABLE is not defined, this is a minimal ANSI-conforming 
implementation of <<_mblen_r>>.  In this case, the
only ``multi-byte character sequences'' recognized are single bytes,
and thus <<1>> is returned unless <[s]> is the null pointer or
has a length of 0 or is the empty string.

When _MB_CAPABLE is defined, this routine calls <<_mbtowc_r>> to perform
the conversion, passing a state variable to allow state dependent
decoding.  The result is based on the locale setting which may
be restricted to a defined set of locales.

RETURNS
This implementation of <<_mblen_r>> returns <<0>> if
<[s]> is <<NULL>> or the empty string; it returns <<1>> if not _MB_CAPABLE or
the character is a single-byte character; it returns <<-1>>
if the multi-byte character is invalid; otherwise it returns
the number of bytes in the multibyte character.

PORTABILITY
<<_mblen>> is required in the ANSI C standard.  However, the precise
effects vary with the locale.

<<_mblen_r>> requires no supporting OS subroutines.
*/

#include <newlib.h>
#include <stdlib.h>
#include <wchar.h>

int
_DEFUN (_mblen_r, (r, s, n, state), 
        struct _reent *r    _AND
        const char *s _AND
        size_t n _AND
        mbstate_t *state)
{
#ifdef _MB_CAPABLE
  int retval;
  retval = _mbtowc_r (r, NULL, s, n, state);

  if (retval < 0)
    {
      state->__count = 0;
      return -1;
    }

  return retval;
#else /* not _MB_CAPABLE */
  if (s == NULL || *s == '\0')
    return 0;
  if (n == 0)
    return -1;
  return 1;
#endif /* not _MB_CAPABLE */
}

