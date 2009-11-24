/* syscalls.c - non-trap system calls for D10V
 *
 * This file contains system calls that cannot be implemented with
 * a simple "trap 15" instruction.  The ones that can are in trap.S.
 */

#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#undef	errno

void _exit (int n);	/* in trap.S */

extern int _write (int fd, const void *ptr, size_t len);

int errno;

register char *stack_ptr asm ("sp");

caddr_t
_sbrk (int incr)
{
  extern char end;		/* Defined by the linker */
  static char *heap_end;
  char *prev_heap_end;
  char *sp = (char *)stack_ptr;

  if (heap_end == 0)
    {
      heap_end = (char *)((((unsigned short) &end) + 7) & ~7);
    }
  prev_heap_end = heap_end;
  if (heap_end + incr > sp)
    {
      _write (2, "Heap and stack collision\n", sizeof ("Heap and stack collision\n")-1);
      abort ();
    }
  heap_end += incr;
  if ((unsigned short)heap_end > 0xbfff
      || (heap_end < prev_heap_end && incr > 0)
      || (heap_end < (char *)((((unsigned short) &end) + 7) & ~7)))
    {
      _write (2, "Too much memory was allocated\n", sizeof ("Too much memory was allocated\n")-1);
      abort ();
    }

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
_unlink ()
{
  errno = ENOSYS;
  return -1;
}

int
isatty (int fd)
{
  return 1;
}

void
_raise ()
{
}

/* If this library is compiled with -mint32, provide conversion functions for
   the system call traps.  */

#if __INT__==32
extern short _read16 (short fd, void *ptr, short len);
int
_read (int fd, void *ptr, size_t len)
{
  return _read16 ((short)fd, ptr, (short)len);
}

extern short _write16 (short fd, const void *ptr, short len);
int
_write (int fd, const void *ptr, size_t len)
{
  return _write16 ((short)fd, ptr, (short)len);
}

extern short _lseek16 (short fd, long offset, short whence);
int
_lseek (int fd, off_t offset, int whence)
{
  return _lseek16 ((short)fd, offset, (short)whence);
}

extern short _close16 (short fd);
int
_close (int fd)
{
  return _close16 ((short)fd);
}

extern short _open16 (const char *name, short flags, short mode);
int
_open (const char *name, int flags, mode_t mode)
{
  return _open16 (name, (short)flags, (short)mode);
}

extern short _creat16 (const char *name, mode_t mode);
int
_creat (const char *name, mode_t mode)
{
  return _creat16 (name, mode);
}

extern void _exit16 (short status);
void
_exit (int status)
{
  _exit16 ((short)status);
}

extern short _stat16 (const char *name, struct stat *stat_pkt);
int
_stat (const char *name, struct stat *stat_pkt)
{
  return _stat16 (name, stat_pkt);
}

extern short _chmod16 (const char *name, short mode);
int
_chmod (const char *name, mode_t mode)
{
  return _chmod16 (name, (short)mode);
}

extern short _chown16 (const char *name, short uid, short gid);
int
_chown (const char *name, uid_t uid, gid_t gid)
{
  return _chown16 (name, (short)uid, (short)gid);
}

extern short _fork16 (void);
int
_fork (void)
{
  return _fork16 ();
}

extern short _wait16 (short *status);
int
_wait (int *status)
{
  if (status)
    {
      short status16;
      short ret = _wait16 (&status16);
      if (ret >= 0)
	*status = status16;
      return ret;
    }
  else
    return _wait16 ((short *)0);
}

extern short _execve16 (const char *filename, const char *argv [], const char *envp[]);
int
_execve (const char *filename, const char *argv [], const char *envp[])
{
  return _execve16 (filename, argv, envp);
}

extern short _execv16 (const char *filename, const char *argv []);
int
_execv (const char *filename, const char *argv [])
{
  return _execv16 (filename, argv);
}

extern short _pipe16 (short fds[]);
int
_pipe (int fds[])
{
  short fds16[2];
  short ret = _pipe16 (fds16);
  if (ret >= 0)
    {
      fds[0] = fds16[0];
      fds[1] = fds16[1];
    }

  return ret;
}

extern short _getpid16 (void);
int
_getpid (void)
{
  return _getpid16 ();
}

extern short _kill16 (short pid, short sig);
int
_kill (int pid, int sig)
{
  return _kill16 ((short)pid, (short)sig);
}
#endif
