#include "syscalls.h"
#include <sys/time.h>
#include <sys/resource.h>

#ifndef __NR_nice
int nice(int i) {
  return setpriority(PRIO_PROCESS,0,getpriority(PRIO_PROCESS,0)+i);
}
#endif
