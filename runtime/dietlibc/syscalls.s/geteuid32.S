#include "syscalls.h"

#ifdef __NR_geteuid32
syscall_weak(geteuid32,geteuid32,__libc_geteuid32)
#endif
