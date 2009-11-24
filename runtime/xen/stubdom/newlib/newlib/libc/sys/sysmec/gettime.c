#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "sys/syscall.h"
#include "sys/time.h"

int errno;

int __trap0 ();

#define TRAP0(f, p1, p2, p3) __trap0(f, (p1), (p2), (p3))

int
_gettimeofday (struct timeval *tp, void *tzp)
{
  return TRAP0 (SYS_gettimeofday, tp, tzp, 0);
}
