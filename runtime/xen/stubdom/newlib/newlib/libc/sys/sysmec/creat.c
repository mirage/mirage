#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "sys/syscall.h"

int errno;

int __trap0 ();

#define TRAP0(f, p1, p2, p3) __trap0(f, (p1), (p2), (p3))

int
creat (const char *path,
	int mode)
{
  return TRAP0 (SYS_creat, path, mode, 0);
}
