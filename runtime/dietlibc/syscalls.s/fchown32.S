#include "syscalls.h"

#ifdef __NR_fchown32
syscall_weak(fchown32,fchown32,__libc_fchown32)
#endif
