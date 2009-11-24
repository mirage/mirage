#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


void _exit (n)
{
  TRAP0 (SYS_exit, n, 0, 0);
}
