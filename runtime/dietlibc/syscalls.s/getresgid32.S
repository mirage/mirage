#include "syscalls.h"

#ifdef __NR_getresgid32
syscall_weak(getresgid32,getresgid32,__libc_getresgid32)
#endif
