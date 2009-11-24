/* Reentrant versions of fstat system call.  This implementation just
   calls the fstat system call.  */

#include <reent.h>
#include <unistd.h>
#include <sys/stat.h>
#include <_syslist.h>

#ifdef __LARGE64_FILES

/* Some targets provides their own versions of these functions.  Those
   targets should define REENTRANT_SYSCALLS_PROVIDED in TARGET_CFLAGS.  */

#ifdef _REENT_ONLY
#ifndef REENTRANT_SYSCALLS_PROVIDED
#define REENTRANT_SYSCALLS_PROVIDED
#endif
#endif

#ifdef REENTRANT_SYSCALLS_PROVIDED

int _dummy_fstat_syscalls = 1;

#else

/* We use the errno variable used by the system dependent layer.  */
#undef errno
extern int errno;

/*
FUNCTION
	<<_fstat64_r>>---Reentrant version of fstat64
	
INDEX
	_fstat64_r

ANSI_SYNOPSIS
	#include <reent.h>
	int _fstat64_r(struct _reent *<[ptr]>,
		       int <[fd]>, struct stat64 *<[pstat]>);

TRAD_SYNOPSIS
	#include <reent.h>
	int _fstat64_r(<[ptr]>, <[fd]>, <[pstat]>)
	struct _reent *<[ptr]>;
	int <[fd]>;
	struct stat *<[pstat]>;

DESCRIPTION
	This is a reentrant version of <<fstat64>>.  It
	takes a pointer to the global data block, which holds
	<<errno>>.  This function is only enabled on systems
	that define __LARGE64_FILES.
*/

int
_DEFUN (_fstat64_r, (ptr, fd, pstat),
     struct _reent *ptr _AND
     int fd _AND
     struct stat64 *pstat)
{
  int ret;

  errno = 0;
  if ((ret = _fstat64 (fd, pstat)) == -1 && errno != 0)
    ptr->_errno = errno;
  return ret;
}

#endif /* ! defined (REENTRANT_SYSCALLS_PROVIDED) */

#endif /* __LARGE64_FILES */
