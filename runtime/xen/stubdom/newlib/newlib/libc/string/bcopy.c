/*
FUNCTION
	<<bcopy>>---copy memory regions

ANSI_SYNOPSIS
	#include <string.h>
	void bcopy(const void *<[in]>, void *<[out]>, size_t <[n]>);

TRAD_SYNOPSIS
	void bcopy(<[in]>, <[out]>, <[n]>
	const void *<[in]>;
	void *<[out]>;
	size_t <[n]>;

DESCRIPTION
	This function copies <[n]> bytes from the memory region
	pointed to by <[in]> to the memory region pointed to by
	<[out]>.

	This function is implemented in term of <<memmove>>.

PORTABILITY
<<bcopy>> requires no supporting OS subroutines.

QUICKREF
	bcopy - pure
*/

#include <string.h>

void
_DEFUN (bcopy, (b1, b2, length),
	_CONST void *b1 _AND
	void *b2 _AND
	size_t length)
{
  memmove (b2, b1, length);
}
