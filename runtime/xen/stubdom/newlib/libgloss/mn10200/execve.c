#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "trap.h"


int
_execve (const char *path, char *const argv[], char *const envp[])
{
  return TRAP0 (SYS_execve, path, argv, envp);
}
