/*
FUNCTION
	<<swab>>---swap adjacent bytes

ANSI_SYNOPSIS
	#include <unistd.h>
	void swab(const void *<[in]>, void *<[out]>, ssize_t <[n]>);

TRAD_SYNOPSIS
	void swab(<[in]>, <[out]>, <[n]>
	void *<[in]>;
	void *<[out]>;
	ssize_t <[n]>;

DESCRIPTION
	This function copies <[n]> bytes from the memory region
	pointed to by <[in]> to the memory region pointed to by
	<[out]>, exchanging adjacent even and odd bytes.

PORTABILITY
<<swab>> requires no supporting OS subroutines.
*/

#include <unistd.h>

void
_DEFUN (swab, (b1, b2, length),
	_CONST void *b1 _AND
	void *b2 _AND
	ssize_t length)
{
  const char *from = b1;
  char *to = b2;
  ssize_t ptr;
  for (ptr = 1; ptr < length; ptr += 2)
    {
      char p = from[ptr];
      char q = from[ptr-1];
      to[ptr-1] = p;
      to[ptr  ] = q;
    }
  if (ptr == length) /* I.e., if length is odd, */
    to[ptr-1] = 0;   /* then pad with a NUL. */
}
