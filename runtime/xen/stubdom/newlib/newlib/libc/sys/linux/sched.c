/* libc/sys/linux/sched.c - Process scheduling functions */

/* Copyright 2002, Red Hat Inc. */

#include <time.h>
#include <sched.h>
#include <machine/syscall.h>

_syscall1(int,sched_get_priority_max,int,policy);
_syscall1(int,sched_get_priority_min,int,policy);
_syscall2(int,sched_rr_get_interval,pid_t,pid,struct timespec *,interval);
_syscall0(int,sched_yield);

weak_alias(__libc_sched_get_priority_max,__sched_get_priority_max);
weak_alias(__libc_sched_get_priority_min,__sched_get_priority_min);

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 3
_syscall2(int,sched_getparam,pid_t,pid,struct sched_param *,sched);
_syscall1(int,sched_getscheduler,pid_t,pid);
_syscall2(int,sched_setparam,pid_t,pid,const struct sched_param *,sched);
_syscall3(int,sched_setscheduler,pid_t,pid,int,policy,const struct sched_param *,sched);
weak_alias(__libc_sched_getparam,__sched_getparam);
weak_alias(__libc_sched_getscheduler,__sched_getscheduler);
weak_alias(__libc_sched_setscheduler,__sched_setscheduler);
#endif /* !_ELIX_LEVEL || _ELIX_LEVEL >= 3 */

