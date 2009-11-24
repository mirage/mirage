/*
FUNCTION
	<<strerror_r>>---convert error number to string and copy to buffer

INDEX
	strerror_r

ANSI_SYNOPSIS
	#include <string.h>
	char *strerror_r(int <[errnum]>, char *<[buffer]>, size_t <[n]>);

TRAD_SYNOPSIS
	#include <string.h>
	char *strerror_r(<[errnum]>, <[buffer]>, <[n]>)
	int <[errnum]>;
	char *<[buffer]>;
	size_t <[n]>;

DESCRIPTION
<<strerror_r>> converts the error number <[errnum]> into a
string and copies the result into the supplied <[buffer]> for
a length up to <[n]>, including the NUL terminator. The value of 
<[errnum]> is usually a copy of <<errno>>.  If <<errnum>> is not a known 
error number, the result is the empty string.

See <<strerror>> for how strings are mapped to <<errnum>>.

RETURNS
This function returns a pointer to a string.  Your application must
not modify that string.

PORTABILITY
<<strerror_r>> is a GNU extension.

<<strerror_r>> requires no supporting OS subroutines.

*/

#undef __STRICT_ANSI__
#include <errno.h>
#include <string.h>

char *
_DEFUN (strerror_r, (errnum, buffer, n),
	int errnum _AND
	char *buffer _AND
	size_t n)
{
  char *error;
  error = strerror (errnum);

  return strncpy (buffer, (const char *)error, n);
}
