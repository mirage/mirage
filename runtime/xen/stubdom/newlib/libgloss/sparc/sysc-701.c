/* more sparclet syscall support (the rest is in crt0-701.S).  */

#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

int
fstat(int _fd, struct stat* _sbuf)
{
  errno = ENOSYS;
  return -1;
}

int
isatty(int fd)
{
  if (fd < 0)
    {
      errno = EBADF;
      return -1;
    }
  return fd <= 2;
}

int 
getpid()
{
  return 1;
}

int 
kill(int pid)
{
  /* if we knew how to nuke the board, we would... */
  return 0;
}

int
lseek(int _fd, off_t offset, int whence)
{
  errno = ENOSYS;
  return -1;
}

extern char end;
char*
sbrk (int incr)
{
  static char* base;
  char *b;
  if(!base) base = &end;
  b = base;
  base += incr;
  return b;
}
