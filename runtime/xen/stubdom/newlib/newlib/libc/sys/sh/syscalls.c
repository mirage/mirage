#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include "sys/syscall.h"
int errno;

/* This is used by _sbrk.  */
register char *stack_ptr asm ("r15");

int
_read (int file,
       char *ptr,
       int len)
{
  return __trap34 (SYS_read, file, ptr, len);
}

int
_lseek (int file,
	int ptr,
	int dir)
{
  return __trap34 (SYS_lseek, file, ptr, dir);
}

int
_write ( int file,
	 char *ptr,
	 int len)
{
  return __trap34 (SYS_write, file, ptr, len);
}

int
_close (int file)
{
  return __trap34 (SYS_close, file, 0, 0);
}

int
_link (char *old, char *new)
{
  return -1;
}

caddr_t
_sbrk (int incr)
{
  extern char end;		/* Defined by the linker */
  static char *heap_end;
  char *prev_heap_end;

  if (heap_end == 0)
    {
      heap_end = &end;
    }
  prev_heap_end = heap_end;
  if (heap_end + incr > stack_ptr)
    {
      _write (1, "Heap and stack collision\n", 25);
      abort ();
    }
  heap_end += incr;
  return (caddr_t) prev_heap_end;
}

int
_fstat (int file,
	struct stat *st)
{
  st->st_mode = S_IFCHR;
  return 0;
}

int
_open (const char *path,
	int flags)
{
  return __trap34 (SYS_open, path, flags, 0);
}

int
_creat (const char *path,
	int mode)
{
  return __trap34 (SYS_creat, path, mode, 0);
}

int
_unlink ()
{
  return -1;
}

isatty (fd)
     int fd;
{
  return 1;
}

_exit (n)
{
  return __trap34 (SYS_exit, n, 0, 0);
}

_kill (n, m)
{
  return __trap34 (SYS_exit, 0xdead, 0, 0);
}

_getpid (n)
{
  return 1;
}

_raise ()
{
}

int
_stat (const char *path, struct stat *st)

{
  return __trap34 (SYS_stat, path, st, 0);
}

int
_chmod (const char *path, short mode)
{
  return __trap34 (SYS_chmod, path, mode);
}

int
_chown (const char *path, short owner, short group)
{
  return __trap34 (SYS_chown, path, owner, group);
}

int
_utime (path, times)
     const char *path;
     char *times;
{
  return __trap34 (SYS_utime, path, times);
}

int
_fork ()
{
  return __trap34 (SYS_fork);
}

int
_wait (statusp)
     int *statusp;
{
  return __trap34 (SYS_wait);
}

int
_execve (const char *path, char *const argv[], char *const envp[])
{
  return __trap34 (SYS_execve, path, argv, envp);
}

int
_execv (const char *path, char *const argv[])
{
  return __trap34 (SYS_execv, path, argv);
}

int
_pipe (int *fd)
{
  return __trap34 (SYS_pipe, fd);
}

/* This is only provided because _gettimeofday_r and _times_r are
   defined in the same module, so we avoid a link error.  */
clock_t
_times (struct tms *tp)
{
  return -1;
}

int
_gettimeofday (struct timeval *tv, void *tz)
{
  tv->tv_usec = 0;
  tv->tv_sec = __trap34 (SYS_time);
  return 0;
}

static inline int
__setup_argv_for_main (int argc)
{
  char **argv;
  int i = argc;

  argv = __builtin_alloca ((1 + argc) * sizeof (*argv));

  argv[i] = NULL;
  while (i--) {
    argv[i] = __builtin_alloca (1 + __trap34 (SYS_argnlen, i));
    __trap34 (SYS_argn, i, argv[i]);
  }

  return main (argc, argv);
}

int
__setup_argv_and_call_main ()
{
  int argc = __trap34 (SYS_argc);

  if (argc <= 0)
    return main (argc, NULL);
  else
    return __setup_argv_for_main (argc);
}
