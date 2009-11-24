#include <sys/types.h>
#include <sys/stat.h>
#include "syscall.h"
#include "eit.h"

_kill (n, m)
{
  return TRAP0 (SYS_exit, 0xdead, 0, 0);
}
