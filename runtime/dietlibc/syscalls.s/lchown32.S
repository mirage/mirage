#include "syscalls.h"

#ifdef __NR_lchown32
syscall_weak(lchown32,lchown32,__libc_lchown32)
#endif
