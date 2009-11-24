/*
FUNCTION
   <<atof>>, <<atoff>>---string to double or float

INDEX
	atof
INDEX
	atoff

ANSI_SYNOPSIS
	#include <stdlib.h>
        double atof(const char *<[s]>);
        float atoff(const char *<[s]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
        double atof(<[s]>)
        char *<[s]>;

        float atoff(<[s]>)
        char *<[s]>;

DESCRIPTION
<<atof>> converts the initial portion of a string to a <<double>>.
<<atoff>> converts the initial portion of a string to a <<float>>.

The functions parse the character string <[s]>,
locating a substring which can be converted to a floating-point
value. The substring must match the format:
. [+|-]<[digits]>[.][<[digits]>][(e|E)[+|-]<[digits]>]
The substring converted is the longest initial
fragment of <[s]> that has the expected format, beginning with
the first non-whitespace character.  The substring
is empty if <<str>> is empty, consists entirely
of whitespace, or if the first non-whitespace character is
something other than <<+>>, <<->>, <<.>>, or a digit.

<<atof(<[s]>)>> is implemented as <<strtod(<[s]>, NULL)>>.
<<atoff(<[s]>)>> is implemented as <<strtof(<[s]>, NULL)>>.

RETURNS
<<atof>> returns the converted substring value, if any, as a
<<double>>; or <<0.0>>,  if no conversion could be performed.
If the correct value is out of the range of representable values, plus
or minus <<HUGE_VAL>> is returned, and <<ERANGE>> is stored in
<<errno>>.
If the correct value would cause underflow, <<0.0>> is returned
and <<ERANGE>> is stored in <<errno>>.

<<atoff>> obeys the same rules as <<atof>>, except that it
returns a <<float>>.

PORTABILITY
<<atof>> is ANSI C. <<atof>>, <<atoi>>, and <<atol>> are subsumed by <<strod>>
and <<strol>>, but are used extensively in existing code. These functions are
less reliable, but may be faster if the argument is verified to be in a valid
range.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/


#include <stdlib.h>
#include <_ansi.h>

double
_DEFUN (atof, (s),
	_CONST char *s)
{
  return strtod (s, NULL);
}
