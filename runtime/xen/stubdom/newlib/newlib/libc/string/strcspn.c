/*
FUNCTION
	<<strcspn>>---count characters not in string

INDEX
	strcspn

ANSI_SYNOPSIS
	size_t strcspn(const char *<[s1]>, const char *<[s2]>);

TRAD_SYNOPSIS
	size_t strcspn(<[s1]>, <[s2]>)
	char *<[s1]>;
	char *<[s2]>;

DESCRIPTION
	This function computes the length of the initial part of
	the string pointed to by <[s1]> which consists entirely of
	characters <[NOT]> from the string pointed to by <[s2]>
	(excluding the terminating null character).

RETURNS
	<<strcspn>> returns the length of the substring found.

PORTABILITY
<<strcspn>> is ANSI C.

<<strcspn>> requires no supporting OS subroutines.
 */

#include <string.h>

size_t
_DEFUN (strcspn, (s1, s2),
	_CONST char *s1 _AND
	_CONST char *s2)
{
  _CONST char *s = s1;
  _CONST char *c;

  while (*s1)
    {
      for (c = s2; *c; c++)
	{
	  if (*s1 == *c)
	    break;
	}
      if (*c)
	break;
      s1++;
    }

  return s1 - s;
}
