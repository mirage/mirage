#include <sys/types.h>
#include <sys/stat.h>
#include "syscall.h"
#include "eit.h"

void
_exit (n)
{
  TRAP0 (SYS_exit, n, 0, 0);
}
