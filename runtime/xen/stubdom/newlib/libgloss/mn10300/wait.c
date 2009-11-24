#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


int
_wait (statusp)
     int *statusp;
{
  return TRAP0 (SYS_wait, 0, 0, 0);
}
