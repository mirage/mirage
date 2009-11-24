#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <errno.h>

int symlink(const char *path1, const char *path2)
{
  errno = ENOSYS;
  return -1;
}
