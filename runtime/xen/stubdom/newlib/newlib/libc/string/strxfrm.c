/*
FUNCTION
	<<strxfrm>>---transform string

INDEX
	strxfrm

ANSI_SYNOPSIS
	#include <string.h>
	size_t strxfrm(char *<[s1]>, const char *<[s2]>, size_t <[n]>);

TRAD_SYNOPSIS
	#include <string.h>
	size_t strxfrm(<[s1]>, <[s2]>, <[n]>);
	char *<[s1]>;
	char *<[s2]>;
	size_t <[n]>;

DESCRIPTION
	This function transforms the string pointed to by <[s2]> and
	places the resulting string into the array pointed to by
	<[s1]>. The transformation is such that if the <<strcmp>>
	function is applied to the two transformed strings, it returns
	a value greater than, equal to, or less than zero,
	correspoinding to the result of a <<strcoll>> function applied
	to the same two original strings.

	No more than <[n]> characters are placed into the resulting
	array pointed to by <[s1]>, including the terminating null
	character. If <[n]> is zero, <[s1]> may be a null pointer. If
	copying takes place between objects that overlap, the behavior
	is undefined.

	With a C locale, this function just copies.

RETURNS
	The <<strxfrm>> function returns the length of the transformed string
	(not including the terminating null character). If the value returned
	is <[n]> or more, the contents of the array pointed to by
	<[s1]> are indeterminate.

PORTABILITY
<<strxfrm>> is ANSI C.

<<strxfrm>> requires no supporting OS subroutines.

QUICKREF
	strxfrm ansi pure
*/

#include <string.h>

size_t
_DEFUN (strxfrm, (s1, s2, n),
	char *s1 _AND
	_CONST char *s2 _AND
	size_t n)
{
  size_t res;
  res = 0;
  while (n-- > 0)
    {
      if ((*s1++ = *s2++) != '\0')
        ++res;
      else
        return res;
    }
  while (*s2)
    {
      ++s2;
      ++res;
    }

  return res;
}
