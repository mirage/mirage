/*
FUNCTION
<<vec_malloc>>, <<vec_realloc>>, <<vec_free>>---manage vector memory

INDEX
	vec_malloc
INDEX
	vec_realloc
INDEX
	vec_free
INDEX
	_vec_malloc_r
INDEX
	_vec_realloc_r
INDEX
	_vec_free_r

ANSI_SYNOPSIS
	#include <stdlib.h>
	void *vec_malloc(size_t <[nbytes]>);
	void *vec_realloc(void *<[aptr]>, size_t <[nbytes]>);
	void vec_free(void *<[aptr]>);


	void *_vec_malloc_r(void *<[reent]>, size_t <[nbytes]>);
	void *_vec_realloc_r(void *<[reent]>, 
                         void *<[aptr]>, size_t <[nbytes]>);
	void _vec_free_r(void *<[reent]>, void *<[aptr]>);


TRAD_SYNOPSIS
	#include <stdlib.h>
	char *vec_malloc(<[nbytes]>)
	size_t <[nbytes]>;

	char *vec_realloc(<[aptr]>, <[nbytes]>)
	char *<[aptr]>;
	size_t <[nbytes]>;

	void vec_free(<[aptr]>)
	char *<[aptr]>;

	char *_vec_malloc_r(<[reent]>,<[nbytes]>)
	char *<[reent]>;
	size_t <[nbytes]>;

	char *_vec_realloc_r(<[reent]>, <[aptr]>, <[nbytes]>)
	char *<[reent]>;
	char *<[aptr]>;
	size_t <[nbytes]>;

	void _vec_free_r(<[reent]>, <[aptr]>)
	char *<[reent]>;
	char *<[aptr]>;

DESCRIPTION
These functions manage a pool of system memory that is 16-byte aligned..

Use <<vec_malloc>> to request allocation of an object with at least
<[nbytes]> bytes of storage available and is 16-byte aligned.  If the space is 
available, <<vec_malloc>> returns a pointer to a newly allocated block as its result.

If you already have a block of storage allocated by <<vec_malloc>>, but
you no longer need all the space allocated to it, you can make it
smaller by calling <<vec_realloc>> with both the object pointer and the
new desired size as arguments.  <<vec_realloc>> guarantees that the
contents of the smaller object match the beginning of the original object.

Similarly, if you need more space for an object, use <<vec_realloc>> to
request the larger size; again, <<vec_realloc>> guarantees that the
beginning of the new, larger object matches the contents of the
original object.

When you no longer need an object originally allocated by <<vec_malloc>>
or <<vec_realloc>> (or the related function <<vec_calloc>>), return it to the
memory storage pool by calling <<vec_free>> with the address of the object
as the argument.  You can also use <<vec_realloc>> for this purpose by
calling it with <<0>> as the <[nbytes]> argument.

The alternate functions <<_vec_malloc_r>>, <<_vec_realloc_r>>, <<_vec_free_r>>,
are reentrant versions.  The extra argument <[reent]> is a pointer to a reentrancy 
structure.

If you have multiple threads of execution which may call any of these
routines, or if any of these routines may be called reentrantly, then
you must provide implementations of the <<__vec_malloc_lock>> and
<<__vec_malloc_unlock>> functions for your system.  See the documentation
for those functions.

These functions operate by calling the function <<_sbrk_r>> or
<<sbrk>>, which allocates space.  You may need to provide one of these
functions for your system.  <<_sbrk_r>> is called with a positive
value to allocate more space, and with a negative value to release
previously allocated space if it is no longer required.
@xref{Stubs}.

RETURNS
<<vec_malloc>> returns a pointer to the newly allocated space, if
successful; otherwise it returns <<NULL>>.  If your application needs
to generate empty objects, you may use <<vec_malloc(0)>> for this purpose.

<<vec_realloc>> returns a pointer to the new block of memory, or <<NULL>>
if a new block could not be allocated.  <<NULL>> is also the result
when you use `<<vec_realloc(<[aptr]>,0)>>' (which has the same effect as
`<<vec_free(<[aptr]>)>>').  You should always check the result of
<<vec_realloc>>; successful vec_reallocation is not guaranteed even when
you request a smaller object.

<<vec_free>> does not return a result.

PORTABILITY
<<vec_malloc>>, <<vec_realloc>>, and <<vec_free>> are all extensions
specified in the AltiVec Programming Interface Manual.

Supporting OS subroutines required: <<sbrk>>.  */

#include <_ansi.h>
#include <reent.h>
#include <stdlib.h>
#include <malloc.h>

#ifndef _REENT_ONLY

_PTR
_DEFUN (vec_malloc, (nbytes),
	size_t nbytes)		/* get a block */
{
  return _memalign_r (_REENT, 16, nbytes);
}

#endif

