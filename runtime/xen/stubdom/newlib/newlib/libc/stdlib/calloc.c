#ifdef MALLOC_PROVIDED
int _dummy_calloc = 1;
#else
/*
FUNCTION
<<calloc>>---allocate space for arrays

INDEX
	calloc

INDEX
	_calloc_r

ANSI_SYNOPSIS
	#include <stdlib.h>
	void *calloc(size_t <[n]>, size_t <[s]>);
	void *calloc_r(void *<[reent]>, size_t <n>, <size_t> <[s]>);
	
TRAD_SYNOPSIS
	#include <stdlib.h>
	char *calloc(<[n]>, <[s]>)
	size_t <[n]>, <[s]>;

	char *_calloc_r(<[reent]>, <[n]>, <[s]>)
	char *<[reent]>;
	size_t <[n]>;
	size_t <[s]>;



DESCRIPTION
Use <<calloc>> to request a block of memory sufficient to hold an
array of <[n]> elements, each of which has size <[s]>.

The memory allocated by <<calloc>> comes out of the same memory pool
used by <<malloc>>, but the memory block is initialized to all zero
bytes.  (To avoid the overhead of initializing the space, use
<<malloc>> instead.)

The alternate function <<_calloc_r>> is reentrant.
The extra argument <[reent]> is a pointer to a reentrancy structure.

RETURNS
If successful, a pointer to the newly allocated space.

If unsuccessful, <<NULL>>.

PORTABILITY
<<calloc>> is ANSI.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <string.h>
#include <stdlib.h>

#ifndef _REENT_ONLY

_PTR
_DEFUN (calloc, (n, size),
	size_t n _AND
	size_t size)
{
  return _calloc_r (_REENT, n, size);
}

#endif
#endif /* MALLOC_PROVIDED */
