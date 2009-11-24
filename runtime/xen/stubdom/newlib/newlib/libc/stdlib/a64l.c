/*
FUNCTION
<<a64l>>, <<l64a>>---convert between radix-64 ASCII string and long

INDEX
        a64l
INDEX
	l64a

ANSI_SYNOPSIS
        #include <stdlib.h>
        long a64l(const char *<[input]>);
        char *l64a(long <[input]>);

TRAD_SYNOPSIS
        #include <stdlib.h>
        long a64l(<[input]>)
        const char *<[input]>;

        char *l64a(<[input]>)
        long <[input]>;

DESCRIPTION
Conversion is performed between long and radix-64 characters.  The
<<l64a>> routine transforms up to 32 bits of input value starting from
least significant bits to the most significant bits.  The input value
is split up into a maximum of 5 groups of 6 bits and possibly one
group of 2 bits (bits 31 and 30).

Each group of 6 bits forms a value from 0--63 which is translated into
a character as follows:

O+
o     0 = '.'
o     1 = '/'
o     2--11 = '0' to '9'
o     12--37 = 'A' to 'Z'
o     38--63 = 'a' to 'z'
O-

When the remaining bits are zero or all bits have been translated, a
null terminator is appended to the string.  An input value of 0
results in the empty string.

The <<a64l>> function performs the reverse translation.  Each
character is used to generate a 6-bit value for up to 30 bits and then
a 2-bit value to complete a 32-bit result.  The null terminator means
that the remaining digits are 0.  An empty input string or NULL string
results in 0L.  An invalid string results in undefined behavior.  If
the size of a long is greater than 32 bits, the result is sign-extended.

RETURNS
<<l64a>> returns a null-terminated string of 0 to 6 characters.
<<a64l>> returns the 32-bit translated value from the input character string.

PORTABILITY
<<l64a>> and <<a64l>> are non-ANSI and are defined by the Single Unix Specification.

Supporting OS subroutines required: None.
*/

#include <_ansi.h>
#include <stdlib.h>
#include <limits.h>

long
_DEFUN (a64l, (input),
	const char *input)
{
  const char *ptr;
  char ch;
  int i, digit;
  unsigned long result = 0;

  if (input == NULL)
    return 0;

  ptr = input;

  /* it easiest to go from most significant digit to least so find end of input or up
     to 6 characters worth */
  for (i = 0; i < 6; ++i)
    {
      if (*ptr)
	++ptr;
    }

  while (ptr > input)
    {
      ch = *(--ptr);

#if defined(PREFER_SIZE_OVER_SPEED) || defined(__OPTIMIZE_SIZE__)
      if (ch >= 'a')
	digit = (ch - 'a') + 38;
      else if (ch >= 'A')
	digit = (ch - 'A') + 12;
      else if (ch >= '0')
	digit = (ch - '0') + 2;
      else if (ch == '/')
	digit = 1;
      else
	digit = 0;
#else /* !defined(PREFER_SIZE_OVER_SPEED) && !defined(__OPTIMIZE_SIZE__) */
      switch (ch)
	{
	case '/':
	  digit = 1;
	  break;
	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case '8':
	case '9':
	  digit = (ch - '0') + 2;
	  break;
	case 'A':
	case 'B':
	case 'C':
	case 'D':
	case 'E':
	case 'F':
	case 'G':
	case 'H':
	case 'I':
	case 'J':
	case 'K':
	case 'L':
	case 'M':
	case 'N':
	case 'O':
	case 'P':
	case 'Q':
	case 'R':
	case 'S':
	case 'T':
	case 'U':
	case 'V':
	case 'W':
	case 'X':
	case 'Y':
	case 'Z':
	  digit = (ch - 'A') + 12;
	  break;
	case 'a':
	case 'b':
	case 'c':
	case 'd':
	case 'e':
	case 'f':
	case 'g':
	case 'h':
	case 'i':
	case 'j':
	case 'k':
	case 'l':
	case 'm':
	case 'n':
	case 'o':
	case 'p':
	case 'q':
	case 'r':
	case 's':
	case 't':
	case 'u':
	case 'v':
	case 'w':
	case 'x':
	case 'y':
	case 'z':
	  digit = (ch - 'A') + 38;
	  break;
	default:
	  digit = 0;
	  break;
	}
#endif /* !defined(PREFER_SIZE_OVER_SPEED) && !defined(__OPTIMIZE_SIZE__) */ 
      
      result = (result << 6) + digit;
    }

#if LONG_MAX > 2147483647
  /* for implementations where long is > 32 bits, the result must be sign-extended */
  if (result & 0x80000000)
      return (((long)-1 >> 32) << 32) + result;
#endif

  return result;
}




