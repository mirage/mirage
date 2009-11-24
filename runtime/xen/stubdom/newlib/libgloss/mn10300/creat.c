#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


int
creat (const char *path,
	int mode)
{
  return TRAP0 (SYS_creat, path, mode, 0);
}
