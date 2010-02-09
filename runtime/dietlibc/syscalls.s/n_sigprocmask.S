#include "syscalls.h"

#ifdef __NR_sigprocmask
syscall_weak(sigprocmask,__old_sigprocmask,__n_sigprocmask)
#endif
