/*
FUNCTION
	<<isascii>>---ASCII character predicate

INDEX
	isascii

ANSI_SYNOPSIS
	#include <ctype.h>
	int isascii(int <[c]>);

TRAD_SYNOPSIS
	#include <ctype.h>
	int isascii(<[c]>);

DESCRIPTION
<<isascii>> is a macro which returns non-zero when <[c]> is an ASCII
character, and 0 otherwise.  It is defined for all integer values.

You can use a compiled subroutine instead of the macro definition by
undefining the macro using `<<#undef isascii>>'.

RETURNS
<<isascii>> returns non-zero if the low order byte of <[c]> is in the range
0 to 127 (<<0x00>>--<<0x7F>>).

PORTABILITY
<<isascii>> is ANSI C.

No supporting OS subroutines are required.
*/
#include <_ansi.h>
#include <ctype.h>



#undef isascii

int 
_DEFUN(isascii,(c),int c)
{
	return c >= 0 && c< 128;
}
