#include "syscalls.h"

#ifdef __NR_getegid32
syscall_weak(getegid32,getegid32,__libc_getegid32)
#endif
