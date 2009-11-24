#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <errno.h>

int unlink(char *name)
{
  errno = ENOSYS;
  return -1;
}
