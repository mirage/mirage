#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


int
open (const char *path, int flags, int mode)
{
  return TRAP0 (SYS_open, path, flags, mode);
}
