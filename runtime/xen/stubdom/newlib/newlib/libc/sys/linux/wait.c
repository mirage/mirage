/* libc/sys/linux/wait.c - Wait function wrappers */

/* Written 2000 by Werner Almesberger */


#include <sys/wait.h>
#include <machine/syscall.h>


_syscall3(pid_t,waitpid,pid_t,pid,int *,wait_stat,int,options)
_syscall4(pid_t,wait4,pid_t,pid,int *,status,int,options,struct rusage *,rusage)


pid_t __libc_wait3(int *status,int options,struct rusage *rusage)
{
    return __libc_wait4(-1,status,options,rusage);
}
weak_alias(__libc_wait3,wait3)

pid_t __libc_wait(int *status)
{
    return __libc_waitpid(-1,status,0);
}

weak_alias(__libc_waitpid,__libc___waitpid);
weak_alias(__libc_wait,__wait);
weak_alias(__libc_wait,wait);
