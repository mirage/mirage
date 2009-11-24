#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "sys/syscall.h"
int errno;



int
_read (int file,
       char *ptr,
       int len)
{
  return __trap3 (SYS_read, file, ptr, len);
}


int
_lseek (int file,
	int ptr,
	int dir)
{
  return __trap3 (SYS_lseek, file, ptr, dir);
}

static
writechar (char c)
{
  asm ("lda %0" : : "r" (c));
  asm ("wdm");
}



int
_write (
	 int file,
	 char *ptr,
	 int len)
{
  return __trap3 (SYS_write, file, ptr, len);
}



int
_close (int file)
{
  return __trap3 (SYS_close, file, 0, 0);
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
_open (
	char *path,
	int flags)
{
  return __trap3 (SYS_open, path, flags, 0);
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
  return __trap3 (SYS_exit, n, 0, 0);
}


_kill (n, m)
{
  return __trap3 (SYS_exit, 0xdead, 0, 0);
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
  return _trap3 (SYS_stat, path, st, 0);
}

int
_chmod (const char *path, short mode)
{
  return _trap3 (SYS_chmod, path, mode);
}

int
_chown (const char *path, short owner, short group)
{
  return _trap3 (SYS_chown, path, owner, group);
}

int
_utime (path, times)
     const char *path;
     char *times;
{
  return _trap3 (SYS_utime, path, times);
}

int
_fork ()
{
  return _trap3 (SYS_fork);
}

int
_wait (statusp)
     int *statusp;
{
  return _trap3 (SYS_wait);
}

int
_execve (const char *path, char *const argv[], char *const envp[])
{
  return _trap3 (SYS_execve, path, argv, envp);
}

int
_execv (const char *path, char *const argv[])
{
  return _trap3 (SYS_execv, path, argv);
}

int
_pipe (int *fd)
{
  return _trap3 (SYS_pipe, fd);
}
