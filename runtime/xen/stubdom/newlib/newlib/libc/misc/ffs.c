/*
FUNCTION
	<<ffs>>---find first bit set in a word

INDEX
	ffs

ANSI_SYNOPSIS
	int ffs(int <[word]>);

TRAD_SYNOPSIS
	int ffs(<[word]>);

DESCRIPTION

<<ffs>> returns the first bit set in a word.

RETURNS
<<ffs>> returns 0 if <[c]> is 0, 1 if <[c]> is odd, 2 if <[c]> is a multiple of
2, etc.

PORTABILITY
<<ffs>> is not ANSI C.

No supporting OS subroutines are required.  */

#include <_ansi.h>

int
_DEFUN(ffs, (word),
       int word)
{
  int i;

  if (!word)
    return 0;

  i = 0;
  for (;;)
    {
      if (((1 << i++) & word) != 0)
	return i;
    }
}
