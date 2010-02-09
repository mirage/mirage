#include "syscalls.h"

#ifdef __NR_sysctl
syscall(sysctl,_sysctl)
#elif (defined(__NR__sysctl))
syscall(_sysctl,_sysctl)
#endif
