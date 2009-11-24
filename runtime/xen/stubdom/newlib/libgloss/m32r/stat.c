#include <sys/types.h>
#include <sys/stat.h>
#include "syscall.h"
#include "eit.h"

int
_stat (const char *path, struct stat *st)

{
  return TRAP0 (SYS_stat, path, st, 0);
}
