/* Reentrant versions of lseek system call. */

#include <reent.h>
#include <unistd.h>
#include <_syslist.h>

/* Some targets provides their own versions of this functions.  Those
   targets should define REENTRANT_SYSCALLS_PROVIDED in TARGET_CFLAGS.  */

#ifdef __LARGE64_FILES

#ifdef _REENT_ONLY
#ifndef REENTRANT_SYSCALLS_PROVIDED
#define REENTRANT_SYSCALLS_PROVIDED
#endif
#endif

#ifndef REENTRANT_SYSCALLS_PROVIDED

/* We use the errno variable used by the system dependent layer.  */
#undef errno
extern int errno;

/*
FUNCTION
	<<_lseek64_r>>---Reentrant version of lseek
	
INDEX
	_lseek64_r

ANSI_SYNOPSIS
	#include <reent.h>
	off64_t _lseek64_r(struct _reent *<[ptr]>,
		           int <[fd]>, off64_t <[pos]>, int <[whence]>);

TRAD_SYNOPSIS
	#include <reent.h>
	off64_t _lseek64_r(<[ptr]>, <[fd]>, <[pos]>, <[whence]>)
	struct _reent *<[ptr]>;
	int <[fd]>;
	off64_t <[pos]>;
	int <[whence]>;

DESCRIPTION
	This is a reentrant version of <<lseek64>>.  It
	takes a pointer to the global data block, which holds
	<<errno>>.  This function only exists on a system
        with large file support.
*/

_off64_t
_DEFUN (_lseek64_r, (ptr, fd, pos, whence),
     struct _reent *ptr _AND
     int fd _AND
     _off64_t pos _AND
     int whence)
{
  _off64_t ret;

  errno = 0;
  if ((ret = _lseek64 (fd, pos, whence)) == (_off64_t) -1 && errno != 0)
    ptr->_errno = errno;
  return ret;
}

#endif /* ! defined (REENTRANT_SYSCALLS_PROVIDED) */

#endif /* __LARGE64_FILES */
