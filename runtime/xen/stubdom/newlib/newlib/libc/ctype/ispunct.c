
/*
FUNCTION
<<ispunct>>---punctuation character predicate

INDEX
ispunct

ANSI_SYNOPSIS
#include <ctype.h>
int ispunct(int <[c]>);

TRAD_SYNOPSIS
#include <ctype.h>
int ispunct(<[c]>);

DESCRIPTION
<<ispunct>> is a macro which classifies ASCII integer values by table
lookup.  It is a predicate returning non-zero for printable
punctuation characters, and 0 for other characters.  It is defined
only when <<isascii>>(<[c]>) is true or <[c]> is EOF.

You can use a compiled subroutine instead of the macro definition by
undefining the macro using `<<#undef ispunct>>'.

RETURNS
<<ispunct>> returns non-zero if <[c]> is a printable punctuation character 
(<<isgraph(<[c]>) && !isalnum(<[c]>)>>).

PORTABILITY
<<ispunct>> is ANSI C.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <ctype.h>


#undef ispunct
int
_DEFUN(ispunct,(c),int c)
{
	return((_ctype_ + 1)[c] & _P);
}

