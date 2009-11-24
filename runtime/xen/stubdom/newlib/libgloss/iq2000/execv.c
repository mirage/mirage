#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


int
execv (const char *path, char *const argv[])
{
  return TRAP0 (SYS_execv, path, argv, 0);
}
