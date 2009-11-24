/* 
FUNCTION
	<<strnlen>>---character string length
	
INDEX
	strnlen

ANSI_SYNOPSIS
	#include <string.h>
	size_t strnlen(const char *<[str]>, size_t <[n]>);

TRAD_SYNOPSIS
	#include <string.h>
	size_t strnlen(<[str]>, <[n]>)
	char *<[src]>;
	size_t <[n]>;

DESCRIPTION
	The <<strnlen>> function works out the length of the string
	starting at <<*<[str]>>> by counting chararacters until it
	reaches a NUL character or the maximum: <[n]> number of
        characters have been inspected.

RETURNS
	<<strnlen>> returns the character count or <[n]>.

PORTABILITY
<<strnlen>> is a GNU extension.

<<strnlen>> requires no supporting OS subroutines.

*/

#undef __STRICT_ANSI__
#include <_ansi.h>
#include <string.h>

size_t
_DEFUN (strnlen, (str, n),
	_CONST char *str _AND
	size_t n)
{
  _CONST char *start = str;

  while (n-- > 0 && *str)
    str++;

  return str - start;
}
