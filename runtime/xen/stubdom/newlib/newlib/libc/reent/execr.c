/* Reentrant versions of execution system calls.  These
   implementations just call the usual system calls.  */

#include <reent.h>
#include <unistd.h>
#include <sys/wait.h>
#include <_syslist.h>

/* Some targets provides their own versions of these functions.  Those
   targets should define REENTRANT_SYSCALLS_PROVIDED in TARGET_CFLAGS.  */

#ifdef _REENT_ONLY
#ifndef REENTRANT_SYSCALLS_PROVIDED
#define REENTRANT_SYSCALLS_PROVIDED
#endif
#endif

/* If NO_EXEC is defined, we don't need these functions.  */

#if defined (REENTRANT_SYSCALLS_PROVIDED) || defined (NO_EXEC)

int _dummy_exec_syscalls = 1;

#else

/* We use the errno variable used by the system dependent layer.  */
#undef errno
extern int errno;

/*
FUNCTION
	<<_execve_r>>---Reentrant version of execve	
INDEX
	_execve_r

ANSI_SYNOPSIS
	#include <reent.h>
	int _execve_r(struct _reent *<[ptr]>, char *<[name]>,
                      char **<[argv]>, char **<[env]>);

TRAD_SYNOPSIS
	#include <reent.h>
	int _execve_r(<[ptr]>, <[name]>, <[argv]>, <[env]>)
	struct _reent *<[ptr]>;
        char *<[name]>;
        char **<[argv]>;
        char **<[env]>;

DESCRIPTION
	This is a reentrant version of <<execve>>.  It
	takes a pointer to the global data block, which holds
	<<errno>>.
*/

int
_DEFUN (_execve_r, (ptr, name, argv, env),
     struct _reent *ptr _AND
     char *name _AND
     char **argv _AND
     char **env)
{
  int ret;

  errno = 0;
  if ((ret = _execve (name, argv, env)) == -1 && errno != 0)
    ptr->_errno = errno;
  return ret;
}


/*
FUNCTION
	<<_fork_r>>---Reentrant version of fork
	
INDEX
	_fork_r

ANSI_SYNOPSIS
	#include <reent.h>
	int _fork_r(struct _reent *<[ptr]>);

TRAD_SYNOPSIS
	#include <reent.h>
	int _fork_r(<[ptr]>)
	struct _reent *<[ptr]>;

DESCRIPTION
	This is a reentrant version of <<fork>>.  It
	takes a pointer to the global data block, which holds
	<<errno>>.
*/

#ifndef NO_FORK

int
_DEFUN (_fork_r, (ptr),
     struct _reent *ptr)
{
  int ret;

  errno = 0;
  if ((ret = _fork ()) == -1 && errno != 0)
    ptr->_errno = errno;
  return ret;
}

#endif

/*
FUNCTION
	<<_wait_r>>---Reentrant version of wait
	
INDEX
	_wait_r

ANSI_SYNOPSIS
	#include <reent.h>
	int _wait_r(struct _reent *<[ptr]>, int *<[status]>);

TRAD_SYNOPSIS
	#include <reent.h>
	int _wait_r(<[ptr]>, <[status]>)
	struct _reent *<[ptr]>;
	int *<[status]>;

DESCRIPTION
	This is a reentrant version of <<wait>>.  It
	takes a pointer to the global data block, which holds
	<<errno>>.
*/

int
_DEFUN (_wait_r, (ptr, status),
     struct _reent *ptr _AND
     int *status)
{
  int ret;

  errno = 0;
  if ((ret = _wait (status)) == -1 && errno != 0)
    ptr->_errno = errno;
  return ret;
}

#endif /* ! defined (REENTRANT_SYSCALLS_PROVIDED) */
