/*
FUNCTION
	<<toascii>>---force integers to ASCII range

INDEX
	toascii

ANSI_SYNOPSIS
	#include <ctype.h>
	int toascii(int <[c]>);

TRAD_SYNOPSIS
	#include <ctype.h>
	int toascii(<[c]>);
	int (<[c]>);

DESCRIPTION
<<toascii>> is a macro which coerces integers to the ASCII range (0--127) by zeroing any higher-order bits.

You can use a compiled subroutine instead of the macro definition by
undefining this macro using `<<#undef toascii>>'.

RETURNS
<<toascii>> returns integers between 0 and 127.

PORTABILITY
<<toascii>> is not ANSI C.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <ctype.h>
#undef toascii

int
_DEFUN(toascii,(c),int c)
{
  return (c)&0177;
}

