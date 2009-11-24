#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


_read (int file,
       char *ptr,
       size_t len)
{
  return TRAP0 (SYS_read, file, ptr, len);
}
