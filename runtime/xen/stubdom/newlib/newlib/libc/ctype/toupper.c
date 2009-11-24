/*
FUNCTION
	<<toupper>>---translate characters to uppercase

INDEX
	toupper
INDEX
	_toupper

ANSI_SYNOPSIS
	#include <ctype.h>
	int toupper(int <[c]>);
	int _toupper(int <[c]>);

TRAD_SYNOPSIS
	#include <ctype.h>
	int toupper(<[c]>);
	int _toupper(<[c]>);


DESCRIPTION
<<toupper>> is a macro which converts lowercase characters to uppercase,
leaving all other characters unchanged.  It is only defined when
<[c]> is an integer in the range <<EOF>> to <<255>>.

You can use a compiled subroutine instead of the macro definition by
undefining this macro using `<<#undef toupper>>'.

<<_toupper>> performs the same conversion as <<toupper>>, but should
only be used when <[c]> is known to be a lowercase character (<<a>>--<<z>>).

RETURNS
<<toupper>> returns the uppercase equivalent of <[c]> when it is a
character between <<a>> and <<z>>, and <[c]> otherwise.

<<_toupper>> returns the uppercase equivalent of <[c]> when it is a
character between <<a>> and <<z>>.  If <[c]> is not one of these
characters, the behaviour of <<_toupper>> is undefined.

PORTABILITY
<<toupper>> is ANSI C.  <<_toupper>> is not recommended for portable programs.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <ctype.h>

#undef toupper
int
_DEFUN(toupper,(c),int c)
{
  return islower(c) ? c - 'a' + 'A' : c;
}
