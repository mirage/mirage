#include "syscalls.h"

#ifdef __NR_waitpid
syscall_weak(waitpid,waitpid,__libc_waitpid)
#endif
