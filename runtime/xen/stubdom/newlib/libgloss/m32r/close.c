#include <sys/types.h>
#include <sys/stat.h>
#include "syscall.h"
#include "eit.h"

int
_close (int file)
{
  return TRAP0 (SYS_close, file, 0, 0);
}
