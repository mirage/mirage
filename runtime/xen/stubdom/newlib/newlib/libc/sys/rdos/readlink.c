#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <errno.h>
#include <sys/types.h>

int readlink(const char *path, char *buf, size_t bufsize)
{
  errno = ENOSYS;
  return -1;
}
