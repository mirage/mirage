#include "syscalls.h"

#ifdef __NR_getgid32
syscall_weak(getgid32,getgid32,__libc_getgid32)
#endif
