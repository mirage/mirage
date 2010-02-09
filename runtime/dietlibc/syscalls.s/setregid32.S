#include "syscalls.h"

#ifdef __NR_setregid32
syscall_weak(setregid32,setregid32,__libc_setregid32)
#endif
