#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"
#include "sys/time.h"


int
_gettimeofday (struct timeval *tp, void *tzp)
{
  return TRAP0 (SYS_gettimeofday, tp, tzp, 0);
}
