#include "syscalls.h"

#ifdef __NR_setreuid32
syscall_weak(setreuid32,setreuid32,__libc_setreuid32)
#endif
