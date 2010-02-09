#include "syscalls.h"

#ifdef __NR_setuid32
syscall_weak(setuid32,setuid32,__libc_setuid32)
#endif
