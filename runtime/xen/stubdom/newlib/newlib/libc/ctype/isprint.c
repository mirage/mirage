
/*
FUNCTION
	<<isprint>>, <<isgraph>>---printable character predicates

INDEX
	isprint
INDEX
	isgraph

ANSI_SYNOPSIS
	#include <ctype.h>
	int isprint(int <[c]>);
	int isgraph(int <[c]>);

TRAD_SYNOPSIS
	#include <ctype.h>
	int isprint(<[c]>);
	int isgraph(<[c]>);


DESCRIPTION
<<isprint>> is a macro which classifies ASCII integer values by table
lookup.  It is a predicate returning non-zero for printable
characters, and 0 for other character arguments. 
It is defined only when <<isascii>>(<[c]>) is true or <[c]> is EOF.

You can use a compiled subroutine instead of the macro definition by
undefining either macro using `<<#undef isprint>>' or `<<#undef isgraph>>'.

RETURNS
<<isprint>> returns non-zero if <[c]> is a printing character,
(<<0x20>>--<<0x7E>>).
<<isgraph>> behaves identically to <<isprint>>, except that the space
character (<<0x20>>) is excluded.

PORTABILITY
<<isprint>> and <<isgraph>> are ANSI C.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <ctype.h>

#undef isgraph
int
_DEFUN(isgraph,(c),int c)
{
	return((_ctype_ + 1)[c] & (_P|_U|_L|_N));
}


#undef isprint
int
_DEFUN(isprint,(c),int c)
{
	return((_ctype_ + 1)[c] & (_P|_U|_L|_N|_B));
}

