/* VxWorks provides its own version of malloc, and we can't use this
   one because VxWorks does not provide sbrk.  So we have a hook to
   not compile this code.  */

#ifdef MALLOC_PROVIDED

int _dummy_mstats = 1;

#else

/*
FUNCTION
<<mallinfo>>, <<malloc_stats>>, <<mallopt>>---malloc support

INDEX
	mallinfo
INDEX
	malloc_stats
INDEX
	mallopt
INDEX
	_mallinfo_r
INDEX
	_malloc_stats_r
INDEX
	_mallopt_r

ANSI_SYNOPSIS
	#include <malloc.h>
	struct mallinfo mallinfo(void);
	void malloc_stats(void);
	int mallopt(int <[parameter]>, <[value]>);

	struct mallinfo _mallinfo_r(void *<[reent]>);
	void _malloc_stats_r(void *<[reent]>);
	int _mallopt_r(void *<[reent]>, int <[parameter]>, <[value]>);

TRAD_SYNOPSIS
	#include <malloc.h>
	struct mallinfo mallinfo();

	void malloc_stats();

	int mallopt(<[parameter]>, <[value]>)
	int <[parameter]>;
	int <[value]>;

	struct mallinfo _mallinfo_r(<[reent]>);
	char *<[reent]>;

	void _malloc_stats_r(<[reent]>);
	char *<[reent]>;

	int _mallopt_r(<[reent]>, <[parameter]>, <[value]>)
	char *<[reent]>;
	int <[parameter]>;
	int <[value]>;

DESCRIPTION
<<mallinfo>> returns a structure describing the current state of
memory allocation.  The structure is defined in malloc.h.  The
following fields are defined: <<arena>> is the total amount of space
in the heap; <<ordblks>> is the number of chunks which are not in use;
<<uordblks>> is the total amount of space allocated by <<malloc>>;
<<fordblks>> is the total amount of space not in use; <<keepcost>> is
the size of the top most memory block.

<<malloc_stats>> print some statistics about memory allocation on
standard error.

<<mallopt>> takes a parameter and a value.  The parameters are defined
in malloc.h, and may be one of the following: <<M_TRIM_THRESHOLD>>
sets the maximum amount of unused space in the top most block before
releasing it back to the system in <<free>> (the space is released by
calling <<_sbrk_r>> with a negative argument); <<M_TOP_PAD>> is the
amount of padding to allocate whenever <<_sbrk_r>> is called to
allocate more space.

The alternate functions <<_mallinfo_r>>, <<_malloc_stats_r>>, and
<<_mallopt_r>> are reentrant versions.  The extra argument <[reent]>
is a pointer to a reentrancy structure.

RETURNS
<<mallinfo>> returns a mallinfo structure.  The structure is defined
in malloc.h.

<<malloc_stats>> does not return a result.

<<mallopt>> returns zero if the parameter could not be set, or
non-zero if it could be set.

PORTABILITY
<<mallinfo>> and <<mallopt>> are provided by SVR4, but <<mallopt>>
takes different parameters on different systems.  <<malloc_stats>> is
not portable.

*/

#include <_ansi.h>
#include <reent.h>
#include <stdlib.h>
#include <malloc.h>
#include <stdio.h>

#ifndef _REENT_ONLY

struct mallinfo
_DEFUN_VOID (mallinfo)
{
  return _mallinfo_r (_REENT);
}

#if !defined (_ELIX_LEVEL) || _ELIX_LEVEL >= 2
void
_DEFUN_VOID (malloc_stats)
{
  _malloc_stats_r (_REENT);
}

int
_DEFUN (mallopt, (p, v),
	int p _AND
	int v)
{
  return _mallopt_r (_REENT, p, v);
}

#endif /* !_ELIX_LEVEL || _ELIX_LEVEL >= 2 */

#endif

#if !defined (_ELIX_LEVEL) || _ELIX_LEVEL >= 2

/* mstats is now compatibility code.  It used to be real, for a
   previous version of the malloc routines.  It now just calls
   malloc_stats.  */

void
_DEFUN (_mstats_r, (ptr, s),
	struct _reent *ptr _AND
	char *s)
{
  _REENT_SMALL_CHECK_INIT(ptr);
  fiprintf (_stderr_r (ptr), "Memory allocation statistics %s\n", s);
  _malloc_stats_r (ptr);
}

#ifndef _REENT_ONLY
void
_DEFUN (mstats, (s),
	char *s)
{
  _mstats_r (_REENT, s);
}

#endif

#endif /* !_ELIX_LEVEL || _ELIX_LEVEL >= 2 */

#endif /* ! defined (MALLOC_PROVIDED) */
