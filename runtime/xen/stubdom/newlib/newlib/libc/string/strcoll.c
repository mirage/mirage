/*
FUNCTION
	<<strcoll>>---locale-specific character string compare
	
INDEX
	strcoll

ANSI_SYNOPSIS
	#include <string.h>
	int strcoll(const char *<[stra]>, const char * <[strb]>);

TRAD_SYNOPSIS
	#include <string.h>
	int strcoll(<[stra]>, <[strb]>)
	char *<[stra]>;
	char *<[strb]>;

DESCRIPTION
	<<strcoll>> compares the string pointed to by <[stra]> to
	the string pointed to by <[strb]>, using an interpretation
	appropriate to the current <<LC_COLLATE>> state.

RETURNS
	If the first string is greater than the second string,
	<<strcoll>> returns a number greater than zero.  If the two
	strings are equivalent, <<strcoll>> returns zero.  If the first
	string is less than the second string, <<strcoll>> returns a
	number less than zero.

PORTABILITY
<<strcoll>> is ANSI C.

<<strcoll>> requires no supporting OS subroutines.

QUICKREF
	strcoll ansi pure
*/

#include <string.h>

int
_DEFUN (strcoll, (a, b),
	_CONST char *a _AND
	_CONST char *b)

{
  return strcmp (a, b);
}
