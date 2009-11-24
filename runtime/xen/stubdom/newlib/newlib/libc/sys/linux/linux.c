/* libc/sys/linux/linux.c - System-specific system calls */

/* Written 2000 by Werner Almesberger */


/*
 * Most system call wrappers have moved to utilities; future fate of this file
 * is guided by glibc/autoconf compatibility and FFS
 */

#include <machine/syscall.h>


/* _syscall1(int,delete_module,const char *,name) */
