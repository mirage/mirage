#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/unistd.h>
#include "sys/syscall.h"

int errno;

int __trap0 ();

#define TRAP0(f, p1, p2, p3) __trap0(f, (p1), (p2), (p3))

off_t
_lseek (int file,
	off_t ptr,
	int dir)
{
  return TRAP0 (SYS_lseek, file, ptr, dir);
}
