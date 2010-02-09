#include "syscalls.h"

#ifdef __NR_pause
syscall_weak(pause,pause,__libc_pause)
#endif
