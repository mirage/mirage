#ifndef _SCHED_H
#define _SCHED_H 1

#include <time.h>
#include <sys/types.h>

__BEGIN_DECLS

/*
 * Scheduling policies
 */
#define SCHED_OTHER		0
#define SCHED_FIFO		1
#define SCHED_RR		2

/*
 * This is an additional bit set when we want to
 * yield the CPU for one re-schedule..
 */
#define SCHED_YIELD		0x10

struct sched_param {
  int sched_priority;
};

/* END OF COPY form kernel-header */

int __sched_setparam(pid_t pid, const struct sched_param* p);
int sched_setparam(pid_t pid, const struct sched_param* p);

int __sched_getparam(pid_t pid, struct sched_param* p);
int sched_getparam(pid_t pid, struct sched_param* p);

int __sched_getscheduler(pid_t pid);
int sched_getscheduler(pid_t pid);

int __sched_setscheduler(pid_t pid, int policy, const struct sched_param* p);
int sched_setscheduler(pid_t pid, int policy, const struct sched_param* p);

int __sched_yield(void);
int sched_yield(void);

int __sched_get_priority_max(int policy);
int sched_get_priority_max(int policy);

int __sched_get_priority_min(int policy);
int sched_get_priority_min(int policy);

int __sched_rr_get_interval(pid_t pid, struct timespec* tp);
int sched_rr_get_interval(pid_t pid, struct timespec* tp);

#ifdef _GNU_SOURCE
/*
 * cloning flags:
 */
#define CSIGNAL         0x000000ff      /* signal mask to be sent at exit */
#define CLONE_VM        0x00000100      /* set if VM shared between processes */
#define CLONE_FS        0x00000200      /* set if fs info shared between processes */
#define CLONE_FILES     0x00000400      /* set if open files shared between processes */
#define CLONE_SIGHAND   0x00000800      /* set if signal handlers and blocked signals shared */
#define CLONE_PID       0x00001000      /* set if pid shared */
#define CLONE_PTRACE    0x00002000      /* set if we want to let tracing continue on the child too */
#define CLONE_VFORK     0x00004000      /* set if the parent wants the child to wake it up on mm_release */
#define CLONE_PARENT    0x00008000      /* set if we want to have the same parent as the cloner */
#define CLONE_THREAD    0x00010000      /* Same thread group? */

#define CLONE_SIGNAL    (CLONE_SIGHAND | CLONE_THREAD)

int clone(void*(*fn)(void*),void*stack,int flags,void*arg);

int unshare(int flags);
#endif

__END_DECLS

#endif
