#include "syscalls.h"

#ifdef __NR_getgroups32
syscall_weak(getgroups32,getgroups32,__libc_getgroups32)
#endif
