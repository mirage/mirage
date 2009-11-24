#include <sys/types.h>
#include <sys/stat.h>
#include "syscall.h"
#include "eit.h"

int
_utime (path, times)
     const char *path;
     char *times;
{
  return TRAP0 (SYS_utime, path, times, 0);
}
