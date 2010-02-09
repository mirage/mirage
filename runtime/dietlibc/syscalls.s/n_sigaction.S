#include "syscalls.h"

#ifdef __NR_sigaction
syscall_weak(sigaction,__old_sigaction,__n_sigaction)
#endif
