#include <sys/types.h>
#include <sys/stat.h>
#include "syscall.h"
#include "eit.h"

int
_fstat (int file, struct stat *st)
{
  st->st_mode = S_IFCHR;
  return 0;
}
