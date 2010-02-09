#include "dietfeatures.h"
#include "syscalls.h"

#ifdef __NR_lstat64
#ifdef WANT_LARGEFILE_BACKCOMPAT
syscall(lstat64,__dietlibc_lstat64)
#else
syscall(lstat64,lstat64)
#endif
#endif
