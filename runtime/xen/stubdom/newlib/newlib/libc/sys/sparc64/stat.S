! stat() system call

#include "sys/syscallasm.h"

#ifdef REENT
	defsyscall_r (_stat_r, SYS_stat, 2)
#else
	defsyscall (stat, SYS_stat)
#endif
