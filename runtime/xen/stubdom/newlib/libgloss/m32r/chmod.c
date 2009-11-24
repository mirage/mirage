#include <sys/types.h>
#include <sys/stat.h>
#include "syscall.h"
#include "eit.h"

int
_chmod (const char *path, short mode)
{
  return TRAP0 (SYS_chmod, path, mode, 0);
}
