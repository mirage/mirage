
/*
FUNCTION
	<<isblank>>---blank character predicate

INDEX
	isblank

ANSI_SYNOPSIS
	#include <ctype.h>
	int isblank(int <[c]>);

TRAD_SYNOPSIS
	#include <ctype.h>
	int isblank(<[c]>);

DESCRIPTION
<<isblank>> is a macro which classifies ASCII integer values by table
lookup.  It is a predicate returning non-zero for blank characters, and 0 
for other characters.

You can use a compiled subroutine instead of the macro definition by
undefining the macro using `<<#undef isblank>>'.

RETURNS
<<isblank>> returns non-zero if <[c]> is a blank character.

*/

#include <_ansi.h>
#include <ctype.h>



#undef isblank
int
_DEFUN(isblank,(c),int c)
{
	return (c == ' ' || c == '\t');
}
