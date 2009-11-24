! dup2() system call

#include "sys/syscallasm.h"

/* FIXME: rewrite in C to use fcntl */

#ifndef __svr4__	/* svr4 uses fcntl */
	defsyscall (dup2, SYS_dup2)
#endif
