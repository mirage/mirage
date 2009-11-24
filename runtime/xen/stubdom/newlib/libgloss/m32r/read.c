#include <sys/types.h>
#include <sys/stat.h>
#include "syscall.h"
#include "eit.h"

int
_read (int file, char *ptr, int len)
{
  return TRAP0 (SYS_read, file, ptr, len);
}
