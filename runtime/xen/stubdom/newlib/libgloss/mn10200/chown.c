#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"



int
chown (const char *path, short owner, short group)
{
  return TRAP0 (SYS_chown, path, owner, group);
}
