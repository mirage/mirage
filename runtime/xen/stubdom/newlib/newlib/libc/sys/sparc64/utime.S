/* utime() system call */
/* svr4 only, sunos4 version calls utimes */

#ifdef __svr4__

#include "sys/syscallasm.h"

	defsyscall (utime, SYS_utime)

#endif
