/*
FUNCTION
<<vec_calloc>>---allocate space for arrays

INDEX
	vec_calloc

INDEX
	_vec_calloc_r

ANSI_SYNOPSIS
	#include <stdlib.h>
	void *vec_calloc(size_t <[n]>, size_t <[s]>);
	void *vec_calloc_r(void *<[reent]>, size_t <n>, <size_t> <[s]>);
	
TRAD_SYNOPSIS
	#include <stdlib.h>
	char *vec_calloc(<[n]>, <[s]>)
	size_t <[n]>, <[s]>;

	char *_vec_calloc_r(<[reent]>, <[n]>, <[s]>)
	char *<[reent]>;
	size_t <[n]>;
	size_t <[s]>;



DESCRIPTION
Use <<vec_calloc>> to request a block of memory sufficient to hold an
array of <[n]> elements, each of which has size <[s]>.

The memory allocated by <<vec_calloc>> comes out of the same memory pool
used by <<vec_malloc>>, but the memory block is initialized to all zero
bytes.  (To avoid the overhead of initializing the space, use
<<vec_malloc>> instead.)

The alternate function <<_vec_calloc_r>> is reentrant.
The extra argument <[reent]> is a pointer to a reentrancy structure.

RETURNS
If successful, a pointer to the newly allocated space.

If unsuccessful, <<NULL>>.

PORTABILITY
<<vec_calloc>> is an non-ANSI extension described in the AltiVec Programming
Interface Manual.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <string.h>
#include <stdlib.h>

#ifndef _REENT_ONLY

_PTR
_DEFUN (vec_calloc, (n, size),
	size_t n _AND
	size_t size)
{
  return _vec_calloc_r (_REENT, n, size);
}

#endif
