#include "syscalls.h"

#ifndef __NR_fdatasync
#define __NR_fdatasync __NR_fsync
#endif
syscall_weak(fdatasync,fdatasync,__libc_fdatasync)
