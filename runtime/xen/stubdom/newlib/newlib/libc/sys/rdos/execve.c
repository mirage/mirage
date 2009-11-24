#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <errno.h>

int execve( char *name, char **argv, char **env)
{
  errno = ENOSYS;
  return -1;
}
