#include "syscalls.h"

#ifdef __NR_fadvise64_64
syscall(fadvise64_64,fadvise64_64)
#endif
