/* Reentrant versions of times system calls */

#include <reent.h>
#include <time.h>
#include <sys/time.h>
#include <sys/times.h>
#include <_syslist.h>

/* Some targets provides their own versions of these functions.  Those
   targets should define REENTRANT_SYSCALLS_PROVIDED in TARGET_CFLAGS.  */

#ifdef _REENT_ONLY
#ifndef REENTRANT_SYSCALLS_PROVIDED
#define REENTRANT_SYSCALLS_PROVIDED
#endif
#endif

#ifdef REENTRANT_SYSCALLS_PROVIDED

int _dummy_times_syscalls = 1;

#else

/* We use the errno variable used by the system dependent layer.  */
#undef errno
extern int errno;

/*
FUNCTION
	<<_times_r>>---Reentrant version of times

INDEX
	_times_r

ANSI_SYNOPSIS
	#include <reent.h>
	#include <sys/times.h>
	clock_t _times_r(struct _reent *<[ptr]>, struct tms *<[ptms]>);

TRAD_SYNOPSIS
	#include <reent.h>
	#include <sys/times.h>
	clock_t _times_r(<[ptr]>, <[ptms]>)
	struct _reent *<[ptr]>;
	struct tms *<[ptms]>;

DESCRIPTION
	This is a reentrant version of <<times>>.  It
	takes a pointer to the global data block, which holds
	<<errno>>.
*/

clock_t
_DEFUN (_times_r, (ptr, ptms),
     struct _reent *ptr _AND
     struct tms *ptms)
{
  clock_t ret;

  ret = _times (ptms);
  return ret;
}
#endif /* ! defined (REENTRANT_SYSCALLS_PROVIDED) */
