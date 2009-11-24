#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <errno.h>

int getpid()
{
  errno = ENOSYS;
  return -1;
}
