#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


time_t
time (time_t *tloc)
{
  time_t res;
  res = TRAP0 (SYS_time, 0, 0, 0);
  if (tloc)
    *tloc = res;
  return res;
}
