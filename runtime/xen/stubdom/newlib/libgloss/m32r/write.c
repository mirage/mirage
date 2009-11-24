#include <sys/types.h>
#include <sys/stat.h>
#include "syscall.h"
#include "eit.h"

int
_write (int file, char *ptr, int len)
{
  return TRAP0 (SYS_write, file, ptr, len);
}
