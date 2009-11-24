/*
FUNCTION
	<<isalpha>>---alphabetic character predicate

INDEX
	isalpha

ANSI_SYNOPSIS
	#include <ctype.h>
	int isalpha(int <[c]>);

TRAD_SYNOPSIS
	#include <ctype.h>
	int isalpha(<[c]>);

DESCRIPTION
<<isalpha>> is a macro which classifies ASCII integer values by table
lookup.  It is a predicate returning non-zero when <[c]> represents an
alphabetic ASCII character, and 0 otherwise.  It is defined only when
<<isascii>>(<[c]>) is true or <[c]> is EOF.

You can use a compiled subroutine instead of the macro definition by
undefining the macro using `<<#undef isalpha>>'.

RETURNS
<<isalpha>> returns non-zero if <[c]> is a letter (<<A>>--<<Z>> or
<<a>>--<<z>>). 

PORTABILITY
<<isalpha>> is ANSI C.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <ctype.h>

#undef isalpha
int
_DEFUN(isalpha,(c),int c)
{
	return((_ctype_ + 1)[c] & (_U|_L));
}

