/* Reentrant versions of fcntl system call.  This implementation just
   calls the fcntl system call.  */

#include <reent.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <_syslist.h>

/* Some targets provides their own versions of these functions.  Those
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
	<<_fcntl_r>>---Reentrant version of fcntl
	
INDEX
	_fcntl_r

ANSI_SYNOPSIS
	#include <reent.h>
	int _fcntl_r(struct _reent *<[ptr]>,
		     int <[fd]>, int <[cmd]>, <[arg]>);

TRAD_SYNOPSIS
	#include <reent.h>
	int _fcntl_r(<[ptr]>, <[fd]>, <[cmd]>, <[arg]>)
	struct _reent *<[ptr]>;
	int <[fd]>;
	int <[cmd]>;
	int <[arg]>;

DESCRIPTION
	This is a reentrant version of <<fcntl>>.  It
	takes a pointer to the global data block, which holds
	<<errno>>.
*/

int
_DEFUN (_fcntl_r, (ptr, fd, cmd, arg),
     struct _reent *ptr _AND
     int fd _AND
     int cmd _AND
     int arg)
{
  int ret;

  errno = 0;
  if ((ret = _fcntl (fd, cmd, arg)) == -1 && errno != 0)
    ptr->_errno = errno;
  return ret;
}

#endif /* ! defined (REENTRANT_SYSCALLS_PROVIDED) */
