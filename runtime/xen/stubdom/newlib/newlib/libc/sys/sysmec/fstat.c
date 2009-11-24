#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "sys/syscall.h"

int errno;

int __trap0 ();

#define TRAP0(f, p1, p2, p3) __trap0(f, (p1), (p2), (p3))

int
_fstat (int file,
	struct stat *st)
{
  st->st_mode = S_IFCHR;
  st->st_blksize = 4096;
  return 0;
}
