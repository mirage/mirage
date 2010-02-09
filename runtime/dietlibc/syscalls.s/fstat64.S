#include "dietfeatures.h"
#include "syscalls.h"

#ifdef __NR_fstat64
#ifdef WANT_LARGEFILE_BACKCOMPAT
syscall(fstat64,__dietlibc_fstat64)
#else
syscall(fstat64,fstat64)
#endif
#endif
