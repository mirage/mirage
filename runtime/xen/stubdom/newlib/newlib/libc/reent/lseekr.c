/* Reentrant versions of lseek system call. */

#include <reent.h>
#include <unistd.h>
#include <_syslist.h>

/* Some targets provides their own versions of this functions.  Those
   targets should define REENTRANT_SYSCALLS_PROVIDED in TARGET_CFLAGS.  */

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
	<<_lseek_r>>---Reentrant version of lseek
	
INDEX
	_lseek_r

ANSI_SYNOPSIS
	#include <reent.h>
	off_t _lseek_r(struct _reent *<[ptr]>,
		       int <[fd]>, off_t <[pos]>, int <[whence]>);

TRAD_SYNOPSIS
	#include <reent.h>
	off_t _lseek_r(<[ptr]>, <[fd]>, <[pos]>, <[whence]>)
	struct _reent *<[ptr]>;
	int <[fd]>;
	off_t <[pos]>;
	int <[whence]>;

DESCRIPTION
	This is a reentrant version of <<lseek>>.  It
	takes a pointer to the global data block, which holds
	<<errno>>.
*/

_off_t
_DEFUN (_lseek_r, (ptr, fd, pos, whence),
     struct _reent *ptr _AND
     int fd _AND
     _off_t pos _AND
     int whence)
{
  _off_t ret;

  errno = 0;
  if ((ret = _lseek (fd, pos, whence)) == (_off_t) -1 && errno != 0)
    ptr->_errno = errno;
  return ret;
}

#endif /* ! defined (REENTRANT_SYSCALLS_PROVIDED) */
