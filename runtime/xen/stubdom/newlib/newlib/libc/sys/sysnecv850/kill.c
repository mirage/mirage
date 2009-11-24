#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "sys/syscall.h"
#include <reent.h>

int errno;

int __trap0 (int function, int p1, int p2, int p3);

#define TRAP0(f, p1, p2, p3) __trap0(f, (int)(p1), (int)(p2), (int)(p3))

_kill (pid, sig)
     pid_t pid;
     int sig;
{
  return TRAP0 (SYS_exit, 0xdead0000 | sig, 0, 0);
}

