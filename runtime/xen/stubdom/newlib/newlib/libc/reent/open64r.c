/* Reentrant versions of open system call. */

#include <reent.h>
#include <unistd.h>
#include <fcntl.h>
#include <_syslist.h>

#ifdef __LARGE64_FILES

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
	<<_open64_r>>---Reentrant version of open64
	
INDEX
	_open64_r

ANSI_SYNOPSIS
	#include <reent.h>
	int _open64_r(struct _reent *<[ptr]>,
  		      const char *<[file]>, int <[flags]>, int <[mode]>);

TRAD_SYNOPSIS
	#include <reent.h>
	int _open64_r(<[ptr]>, <[file]>, <[flags]>, <[mode]>)
	struct _reent *<[ptr]>;
	char *<[file]>;
	int <[flags]>;
	int <[mode]>;

DESCRIPTION
	This is a reentrant version of <<open64>>.  It
	takes a pointer to the global data block, which holds
	<<errno>>.  This function only exists on systems with
        large file support.
*/

int
_open64_r (ptr, file, flags, mode)
     struct _reent *ptr;
     _CONST char *file;
     int flags;
     int mode;
{
  int ret;

  errno = 0;
  if ((ret = _open64 (file, flags, mode)) == -1 && errno != 0)
    ptr->_errno = errno;
  return ret;
}

#endif /* ! defined (REENTRANT_SYSCALLS_PROVIDED) */

#endif /* __LARGE64_FILES */
