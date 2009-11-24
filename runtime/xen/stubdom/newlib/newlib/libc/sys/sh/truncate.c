#include <_ansi.h>
#include <sys/types.h>
#include "sys/syscall.h"

int
truncate (const char *path, off_t length)
{
  return __trap34 (SYS_truncate, path, length, 0);
}
