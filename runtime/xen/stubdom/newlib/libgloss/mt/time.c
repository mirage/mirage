#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


time_t
time (time_t *tloc)
{
  return TRAP0 (SYS_time, tloc, 0, 0);
}
