#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

int stat(const char *file, struct stat *st)
{
  errno = ENOSYS;
  return -1;
}
