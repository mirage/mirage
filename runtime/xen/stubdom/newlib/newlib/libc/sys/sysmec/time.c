#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "sys/syscall.h"

int errno;

int __trap0 ();

#define TRAP0(f, p1, p2, p3) __trap0(f, (p1), (p2), (p3))

time_t
time (time_t *tloc)
{
  return TRAP0 (SYS_time, tloc, 0, 0);
}
