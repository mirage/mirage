#include "syscalls.h"

#ifdef __NR_signalfd
syscall(signalfd,__signalfd)
#endif
