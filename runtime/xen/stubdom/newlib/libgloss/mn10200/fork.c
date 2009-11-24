#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


int
_fork ()
{
  return TRAP0 (SYS_fork, 0, 0, 0);
}
