/* VxWorks provides its own version of malloc, and we can't use this
   one because VxWorks does not provide sbrk.  So we have a hook to
   not compile this code.  */

/* The routines here are simple cover fns to the routines that do the real
   work (the reentrant versions).  */
/* FIXME: Does the warning below (see WARNINGS) about non-reentrancy still
   apply?  A first guess would be "no", but how about reentrancy in the *same*
   thread?  */

#ifdef MALLOC_PROVIDED

int _dummy_malloc = 1;

#else

/*
FUNCTION
<<malloc>>, <<realloc>>, <<free>>---manage memory

INDEX
	malloc
INDEX
	realloc
INDEX
	free
INDEX
	memalign
INDEX
	malloc_usable_size
INDEX
	_malloc_r
INDEX
	_realloc_r
INDEX
	_free_r
INDEX
	_memalign_r
INDEX
	_malloc_usable_size_r

ANSI_SYNOPSIS
	#include <stdlib.h>
	void *malloc(size_t <[nbytes]>);
	void *realloc(void *<[aptr]>, size_t <[nbytes]>);
	void free(void *<[aptr]>);

	void *memalign(size_t <[align]>, size_t <[nbytes]>);

	size_t malloc_usable_size(void *<[aptr]>);

	void *_malloc_r(void *<[reent]>, size_t <[nbytes]>);
	void *_realloc_r(void *<[reent]>, 
                         void *<[aptr]>, size_t <[nbytes]>);
	void _free_r(void *<[reent]>, void *<[aptr]>);

	void *_memalign_r(void *<[reent]>,
			  size_t <[align]>, size_t <[nbytes]>);

	size_t _malloc_usable_size_r(void *<[reent]>, void *<[aptr]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	char *malloc(<[nbytes]>)
	size_t <[nbytes]>;

	char *realloc(<[aptr]>, <[nbytes]>)
	char *<[aptr]>;
	size_t <[nbytes]>;

	void free(<[aptr]>)
	char *<[aptr]>;

	char *memalign(<[align]>, <[nbytes]>)
	size_t <[align]>;
	size_t <[nbytes]>;

	size_t malloc_usable_size(<[aptr]>)
	char *<[aptr]>;

	char *_malloc_r(<[reent]>,<[nbytes]>)
	char *<[reent]>;
	size_t <[nbytes]>;

	char *_realloc_r(<[reent]>, <[aptr]>, <[nbytes]>)
	char *<[reent]>;
	char *<[aptr]>;
	size_t <[nbytes]>;

	void _free_r(<[reent]>, <[aptr]>)
	char *<[reent]>;
	char *<[aptr]>;

	char *_memalign_r(<[reent]>, <[align]>, <[nbytes]>)
	char *<[reent]>;
	size_t <[align]>;
	size_t <[nbytes]>;

	size_t malloc_usable_size(<[reent]>, <[aptr]>)
	char *<[reent]>;
	char *<[aptr]>;

DESCRIPTION
These functions manage a pool of system memory.

Use <<malloc>> to request allocation of an object with at least
<[nbytes]> bytes of storage available.  If the space is available,
<<malloc>> returns a pointer to a newly allocated block as its result.

If you already have a block of storage allocated by <<malloc>>, but
you no longer need all the space allocated to it, you can make it
smaller by calling <<realloc>> with both the object pointer and the
new desired size as arguments.  <<realloc>> guarantees that the
contents of the smaller object match the beginning of the original object.

Similarly, if you need more space for an object, use <<realloc>> to
request the larger size; again, <<realloc>> guarantees that the
beginning of the new, larger object matches the contents of the
original object.

When you no longer need an object originally allocated by <<malloc>>
or <<realloc>> (or the related function <<calloc>>), return it to the
memory storage pool by calling <<free>> with the address of the object
as the argument.  You can also use <<realloc>> for this purpose by
calling it with <<0>> as the <[nbytes]> argument.

The <<memalign>> function returns a block of size <[nbytes]> aligned
to a <[align]> boundary.  The <[align]> argument must be a power of
two.

The <<malloc_usable_size>> function takes a pointer to a block
allocated by <<malloc>>.  It returns the amount of space that is
available in the block.  This may or may not be more than the size
requested from <<malloc>>, due to alignment or minimum size
constraints.

The alternate functions <<_malloc_r>>, <<_realloc_r>>, <<_free_r>>,
<<_memalign_r>>, and <<_malloc_usable_size_r>> are reentrant versions.
The extra argument <[reent]> is a pointer to a reentrancy structure.

If you have multiple threads of execution which may call any of these
routines, or if any of these routines may be called reentrantly, then
you must provide implementations of the <<__malloc_lock>> and
<<__malloc_unlock>> functions for your system.  See the documentation
for those functions.

These functions operate by calling the function <<_sbrk_r>> or
<<sbrk>>, which allocates space.  You may need to provide one of these
functions for your system.  <<_sbrk_r>> is called with a positive
value to allocate more space, and with a negative value to release
previously allocated space if it is no longer required.
@xref{Stubs}.

RETURNS
<<malloc>> returns a pointer to the newly allocated space, if
successful; otherwise it returns <<NULL>>.  If your application needs
to generate empty objects, you may use <<malloc(0)>> for this purpose.

<<realloc>> returns a pointer to the new block of memory, or <<NULL>>
if a new block could not be allocated.  <<NULL>> is also the result
when you use `<<realloc(<[aptr]>,0)>>' (which has the same effect as
`<<free(<[aptr]>)>>').  You should always check the result of
<<realloc>>; successful reallocation is not guaranteed even when
you request a smaller object.

<<free>> does not return a result.

<<memalign>> returns a pointer to the newly allocated space.

<<malloc_usable_size>> returns the usable size.

PORTABILITY
<<malloc>>, <<realloc>>, and <<free>> are specified by the ANSI C
standard, but other conforming implementations of <<malloc>> may
behave differently when <[nbytes]> is zero.

<<memalign>> is part of SVR4.

<<malloc_usable_size>> is not portable.

Supporting OS subroutines required: <<sbrk>>.  */

#include <_ansi.h>
#include <reent.h>
#include <stdlib.h>
#include <malloc.h>

#ifndef _REENT_ONLY

_PTR
_DEFUN (malloc, (nbytes),
	size_t nbytes)		/* get a block */
{
  return _malloc_r (_REENT, nbytes);
}

void
_DEFUN (free, (aptr),
	_PTR aptr)
{
  _free_r (_REENT, aptr);
}

#endif

#endif /* ! defined (MALLOC_PROVIDED) */
