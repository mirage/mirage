
/*
FUNCTION
<<isxdigit>>---hexadecimal digit predicate

INDEX
isxdigit

ANSI_SYNOPSIS
#include <ctype.h>
int isxdigit(int <[c]>);

TRAD_SYNOPSIS
#include <ctype.h>
int isxdigit(int <[c]>);

DESCRIPTION
<<isxdigit>> is a macro which classifies ASCII integer values by table
lookup.  It is a predicate returning non-zero for hexadecimal digits,
and <<0>> for other characters.  It is defined only when
<<isascii>>(<[c]>) is true or <[c]> is EOF.

You can use a compiled subroutine instead of the macro definition by
undefining the macro using `<<#undef isxdigit>>'.

RETURNS
<<isxdigit>> returns non-zero if <[c]> is a hexadecimal digit
(<<0>>--<<9>>, <<a>>--<<f>>, or <<A>>--<<F>>).

PORTABILITY
<<isxdigit>> is ANSI C.

No supporting OS subroutines are required.
*/
#include <_ansi.h>
#include <ctype.h>


#undef isxdigit
int
_DEFUN(isxdigit,(c),int c)
{
	return((_ctype_ + 1)[c] & ((_X)|(_N)));
}

