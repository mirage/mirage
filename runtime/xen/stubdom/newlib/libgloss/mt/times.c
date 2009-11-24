#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"
#include "sys/times.h"


clock_t
times (struct tms *buffer)
{
  return TRAP0 (SYS_times, buffer, 0, 0);
}
