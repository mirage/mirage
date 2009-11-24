/*
FUNCTION
<<system>>---execute command string

INDEX
	system
INDEX
	_system_r

ANSI_SYNOPSIS
	#include <stdlib.h>
	int system(char *<[s]>);

	int _system_r(void *<[reent]>, char *<[s]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	int system(<[s]>)
	char *<[s]>;

	int _system_r(<[reent]>, <[s]>)
	char *<[reent]>;
	char *<[s]>;

DESCRIPTION

Use <<system>> to pass a command string <<*<[s]>>> to <</bin/sh>> on
your system, and wait for it to finish executing.

Use ``<<system(NULL)>>'' to test whether your system has <</bin/sh>>
available.

The alternate function <<_system_r>> is a reentrant version.  The
extra argument <[reent]> is a pointer to a reentrancy structure.

RETURNS
<<system(NULL)>> returns a non-zero value if <</bin/sh>> is available, and
<<0>> if it is not.

With a command argument, the result of <<system>> is the exit status
returned by <</bin/sh>>.

PORTABILITY
ANSI C requires <<system>>, but leaves the nature and effects of a
command processor undefined.  ANSI C does, however, specify that
<<system(NULL)>> return zero or nonzero to report on the existence of
a command processor.

POSIX.2 requires <<system>>, and requires that it invoke a <<sh>>.
Where <<sh>> is found is left unspecified.

Supporting OS subroutines required: <<_exit>>, <<_execve>>, <<_fork_r>>,
<<_wait_r>>.
*/

#include <errno.h>
#include <stddef.h>
#include <stdlib.h>
#include <unistd.h>
#include <_syslist.h>
#include <reent.h>

#if defined (unix) || defined (__CYGWIN__)
static int do_system ();
#endif

int
_system_r (ptr, s)
     struct _reent *ptr;
     _CONST char *s;
{
#if defined(HAVE_SYSTEM)
  return _system (s);
  ptr = ptr;
#elif defined(NO_EXEC)
  if (s == NULL)
    return 0;
  errno = ENOSYS;
  return -1;
#else

  /* ??? How to handle (s == NULL) here is not exactly clear.
     If _fork_r fails, that's not really a justification for returning 0.
     For now we always return 0 and leave it to each target to explicitly
     handle otherwise (this can always be relaxed in the future).  */

#if defined (unix) || defined (__CYGWIN__)
  if (s == NULL)
    return 1;
  return do_system (ptr, s);
#else
  if (s == NULL)
    return 0;
  errno = ENOSYS;
  return -1;
#endif

#endif
}

#ifndef _REENT_ONLY

int
system (s)
     _CONST char *s;
{
  return _system_r (_REENT, s);
}

#endif

#if defined (unix) && !defined (__CYGWIN__) && !defined(__rtems__)
extern char **environ;

/* Only deal with a pointer to environ, to work around subtle bugs with shared
   libraries and/or small data systems where the user declares his own
   'environ'.  */
static char ***p_environ = &environ;

static int
do_system (ptr, s)
     struct _reent *ptr;
     _CONST char *s;
{
  char *argv[4];
  int pid, status;

  argv[0] = "sh";
  argv[1] = "-c";
  argv[2] = (char *) s;
  argv[3] = NULL;

  if ((pid = _fork_r (ptr)) == 0)
    {
      _execve ("/bin/sh", argv, *p_environ);
      exit (100);
    }
  else if (pid == -1)
    return -1;
  else
    {
      int rc = _wait_r (ptr, &status);
      if (rc == -1)
	return -1;
      status = (status >> 8) & 0xff;
      return status;
    }
}
#endif

#if defined (__CYGWIN__)
static int
do_system (ptr, s)
     struct _reent *ptr;
     _CONST char *s;
{
  char *argv[4];
  int pid, status;

  argv[0] = "sh";
  argv[1] = "-c";
  argv[2] = (char *) s;
  argv[3] = NULL;

  if ((pid = vfork ()) == 0)
    {
      /* ??? It's not clear what's the right path to take (pun intended :-).
	 There won't be an "sh" in any fixed location so we need each user
	 to be able to say where to find "sh".  That suggests using an
	 environment variable, but after a few more such situations we may
	 have too many of them.  */
      char *sh = getenv ("SH_PATH");
      if (sh == NULL)
	sh = "/bin/sh";
      _execve (sh, argv, environ);
      exit (100);
    }
  else if (pid == -1)
    return -1;
  else
    {
      extern int _wait (int *);
      int rc = _wait (&status);
      if (rc == -1)
	return -1;
      status = (status >> 8) & 0xff;
      return status;
    }
}
#endif
