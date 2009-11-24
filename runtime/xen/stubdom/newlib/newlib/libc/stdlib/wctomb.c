/*
FUNCTION
<<wctomb>>---minimal wide char to multibyte converter

INDEX
	wctomb

ANSI_SYNOPSIS
	#include <stdlib.h>
	int wctomb(char *<[s]>, wchar_t <[wchar]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	int wctomb(<[s]>, <[wchar]>)
	char *<[s]>;
	wchar_t <[wchar]>;

DESCRIPTION
When _MB_CAPABLE is not defined, this is a minimal ANSI-conforming 
implementation of <<wctomb>>.  The
only ``wide characters'' recognized are single bytes,
and they are ``converted'' to themselves.  

When _MB_CAPABLE is defined, this routine calls <<_wctomb_r>> to perform
the conversion, passing a state variable to allow state dependent
decoding.  The result is based on the locale setting which may
be restricted to a defined set of locales.

Each call to <<wctomb>> modifies <<*<[s]>>> unless <[s]> is a null
pointer or _MB_CAPABLE is defined and <[wchar]> is invalid.

RETURNS
This implementation of <<wctomb>> returns <<0>> if
<[s]> is <<NULL>>; it returns <<-1>> if _MB_CAPABLE is enabled
and the wchar is not a valid multi-byte character, it returns <<1>>
if _MB_CAPABLE is not defined or the wchar is in reality a single
byte character, otherwise it returns the number of bytes in the
multi-byte character.

PORTABILITY
<<wctomb>> is required in the ANSI C standard.  However, the precise
effects vary with the locale.

<<wctomb>> requires no supporting OS subroutines.
*/

#ifndef _REENT_ONLY

#include <newlib.h>
#include <stdlib.h>

int
_DEFUN (wctomb, (s, wchar),
        char *s _AND
        wchar_t wchar)
{
#ifdef _MB_CAPABLE
        _REENT_CHECK_MISC(_REENT);

        return _wctomb_r (_REENT, s, wchar, &(_REENT_WCTOMB_STATE(_REENT)));
#else /* not _MB_CAPABLE */
        if (s == NULL)
                return 0;

        *s = (char) wchar;
        return 1;
#endif /* not _MB_CAPABLE */
}

#endif /* !_REENT_ONLY */
