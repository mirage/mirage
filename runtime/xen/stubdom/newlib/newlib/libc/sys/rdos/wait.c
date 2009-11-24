#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <errno.h>

int wait(int *status)
{
  errno = ENOSYS;
  return -1;
}
