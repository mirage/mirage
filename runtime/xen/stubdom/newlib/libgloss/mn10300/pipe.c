#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


int
pipe (int fd)
{
  return TRAP0 (SYS_pipe, fd, 0, 0);
}
