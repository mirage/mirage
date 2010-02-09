#include "syscalls.h"

#ifdef __NR_setfsuid32
syscall_weak(setfsuid32,setfsuid32,__libc_setfsuid32)
#endif
