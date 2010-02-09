#include "syscalls.h"

#ifdef __NR_chown32
syscall_weak(chown32,chown32,__libc_chown32)
#endif
