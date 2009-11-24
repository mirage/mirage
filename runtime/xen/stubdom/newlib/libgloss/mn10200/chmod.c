#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


int
chmod (const char *path, mode_t mode)
{
  return TRAP0 (SYS_chmod, path, mode, 0);
}
