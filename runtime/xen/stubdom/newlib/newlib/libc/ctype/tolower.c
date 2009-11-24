/*
FUNCTION
	<<tolower>>---translate characters to lowercase

INDEX
	tolower
INDEX
	_tolower

ANSI_SYNOPSIS
	#include <ctype.h>
	int tolower(int <[c]>);
	int _tolower(int <[c]>);

TRAD_SYNOPSIS
	#include <ctype.h>
	int tolower(<[c]>);
	int _tolower(<[c]>);


DESCRIPTION
<<tolower>> is a macro which converts uppercase characters to lowercase,
leaving all other characters unchanged.  It is only defined when
<[c]> is an integer in the range <<EOF>> to <<255>>.

You can use a compiled subroutine instead of the macro definition by
undefining this macro using `<<#undef tolower>>'.

<<_tolower>> performs the same conversion as <<tolower>>, but should
only be used when <[c]> is known to be an uppercase character (<<A>>--<<Z>>).

RETURNS
<<tolower>> returns the lowercase equivalent of <[c]> when it is a
character between <<A>> and <<Z>>, and <[c]> otherwise.

<<_tolower>> returns the lowercase equivalent of <[c]> when it is a
character between <<A>> and <<Z>>.  If <[c]> is not one of these
characters, the behaviour of <<_tolower>> is undefined.

PORTABILITY
<<tolower>> is ANSI C.  <<_tolower>> is not recommended for portable
programs.

No supporting OS subroutines are required.
*/ 

#include <_ansi.h>
#include <ctype.h>

#undef tolower
int
_DEFUN(tolower,(c),int c)
{
	return isupper(c) ? (c) - 'A' + 'a' : c;
}
