#include <sys/types.h>
#include <sys/stat.h>

static char *heap_end = 0;

int
brk (void *ptr)
{
  heap_end = ptr;
  return 0;
}

caddr_t
sbrk (int amt)
{
  extern char end;
  char *prev_heap_end;

  if (heap_end == 0) 
    heap_end = &end;
  prev_heap_end = heap_end;
  heap_end += amt;
  return ((caddr_t) prev_heap_end);
}

int
isatty (int file)
{
  return file<3;
}

int
fstat (int file, struct stat *st)
{
  st->st_mode = S_IFCHR;
  return 0;
}

int
stat (const char *filename, struct stat *st)
{
  st->st_mode = S_IFCHR;
  return 0;
}

int
lseek (int fd, off_t offset, int type)
{
  return _sys_lseek (fd, offset, type);
}

int
open (char *file, int mode, int perms)
{
  return _sys_open (file, mode, perms);
}

int
close (int fd)
{
  return _sys_close (fd);
}

int
getpid ()
{
  return -1;
}

int
kill (int pid, int signal)
{
  exit (signal);
}

#if 0
/* This conflicts with the abort defined in newlib.  */
void
abort ()
{
  exit (6);
}
#endif
