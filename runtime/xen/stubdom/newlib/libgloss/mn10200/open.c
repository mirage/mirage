#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


int
_open (const char *path,
	int flags)
{
  return TRAP0 (SYS_open, path, flags, 0);
}
