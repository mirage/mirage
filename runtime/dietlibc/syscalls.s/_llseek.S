#include "syscalls.h"

#ifdef __NR__llseek
.global llseek
.type	llseek,function
llseek:
syscall(_llseek,_llseek)
#endif
