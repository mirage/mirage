#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


_kill (n, m)
{
  return TRAP0 (SYS_exit, 0xdead, 0, 0);
}

