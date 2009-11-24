/* EL/IX level 1 and 2 libraries don't have the following syscalls,
   but we need them due to our threading model based on processes */

#include <time.h>
#include <sched.h>
#include <sys/wait.h>
#include <machine/syscall.h>

#define __NR___waitpid __NR_waitpid
#define __NR___sched_getparam __NR_sched_getparam
#define __NR___sched_getscheduler __NR_sched_getscheduler
#define __NR___sched_setscheduler __NR_sched_setscheduler

_syscall2(int,__sched_getparam,pid_t,pid,struct sched_param *,sched);
_syscall1(int,__sched_getscheduler,pid_t,pid);
_syscall3(int,__sched_setscheduler,pid_t,pid,int,policy,const struct sched_param *,sched);

/* we want __libc____waitpid defined to support __waitpid which is
   defined in wrapsyscall.c */
_syscall3_base(pid_t,__waitpid,pid_t,pid,int *,wait_stat,int,options)
