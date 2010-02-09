#include "syscalls.h"

#ifdef __NR_statfs64
syscall(statfs64,__dietlibc_statfs64)
#endif
