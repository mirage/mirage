#include "syscalls.h"

#ifdef __NR_fstatfs64
syscall(fstatfs64,__dietlibc_fstatfs64)
#endif
