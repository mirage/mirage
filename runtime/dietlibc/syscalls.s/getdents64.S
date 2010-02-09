#include "dietfeatures.h"
#include "syscalls.h"

#ifdef __NR_getdents64
syscall(getdents64,getdents64)
#endif
