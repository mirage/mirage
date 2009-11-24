#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <errno.h>

int kill(int pid, int sig)
{
  errno = ENOSYS;
  return -1;
}
