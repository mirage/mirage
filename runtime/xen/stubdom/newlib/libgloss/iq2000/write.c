#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


int
_write ( int file,
	 char *ptr,
	 size_t len)
{
  return TRAP0 (SYS_write, file, ptr, len);
}
