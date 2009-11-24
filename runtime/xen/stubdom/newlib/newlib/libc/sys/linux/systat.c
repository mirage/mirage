/* libc/sys/linux/systat.c - System calls related to overall system state */

/* Written 2000 by Werner Almesberger */


#include <sys/utsname.h>
#include <machine/syscall.h>


_syscall1(int,uname,struct utsname *,name)
