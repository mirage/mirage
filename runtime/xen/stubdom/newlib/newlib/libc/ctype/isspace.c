
/*
FUNCTION
	<<isspace>>---whitespace character predicate

INDEX
	isspace

ANSI_SYNOPSIS
	#include <ctype.h>
	int isspace(int <[c]>);

TRAD_SYNOPSIS
	#include <ctype.h>
	int isspace(<[c]>);

DESCRIPTION
<<isspace>> is a macro which classifies ASCII integer values by table
lookup.  It is a predicate returning non-zero for whitespace
characters, and 0 for other characters.  It is defined only when <<isascii>>(<[c]>) is true or <[c]> is EOF.

You can use a compiled subroutine instead of the macro definition by
undefining the macro using `<<#undef isspace>>'.

RETURNS
<<isspace>> returns non-zero if <[c]> is a space, tab, carriage return, new
line, vertical tab, or formfeed (<<0x09>>--<<0x0D>>, <<0x20>>).

PORTABILITY
<<isspace>> is ANSI C.

No supporting OS subroutines are required.
*/
#include <_ansi.h>
#include <ctype.h>


#undef isspace
int
_DEFUN(isspace,(c),int c)
{
	return((_ctype_ + 1)[c] & _S);
}

