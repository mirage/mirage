/* libc/sys/linux/signal.c - Signal handling functions */

/* Written 2000 by Werner Almesberger */


#include <signal.h>
#include <unistd.h>
#include <sys/types.h>
#include <machine/syscall.h>

/* avoid name space pollution */
#define __NR___sgetmask __NR_sgetmask
#define __NR___ssetmask __NR_ssetmask
#define __NR___rt_sigtimedwait __NR_rt_sigtimedwait
#define __NR___rt_sigpending __NR_rt_sigpending
#define __NR___rt_sigprocmask __NR_rt_sigprocmask
#define __NR___rt_sigsuspend __NR_rt_sigsuspend

_syscall2(int,kill,pid_t,pid,int,sig)
_syscall2(__sighandler_t,signal,int,signum,__sighandler_t,handler)
_syscall0(int,pause)
_syscall1(unsigned int,alarm,unsigned int,seconds)

static _syscall2(int,__rt_sigpending,sigset_t *,set,size_t,size)
static _syscall4(int,__rt_sigprocmask,int,how,const sigset_t *,set,sigset_t *,oldset,size_t,size)
static _syscall2(int,__rt_sigsuspend,const sigset_t *,mask,size_t,size)
static _syscall4(int,__rt_sigtimedwait,const sigset_t *,set,siginfo_t *,info,struct timespec *,timeout,size_t,size)

int __sigsuspend (const sigset_t *mask)
{
    return __rt_sigsuspend(mask, NSIG/8);
}
weak_alias(__sigsuspend,sigsuspend)

int sigmask(int signum) /* BSD */
{
    return 1 << signum;
}

int __libc_raise(int sig)
{
    return kill(getpid(),sig);
}
weak_alias(__libc_raise,raise)

int __sigpending(sigset_t *set)
{
  return __rt_sigpending(set, NSIG/8);
}
weak_alias(__sigpending,sigpending)

int __sigprocmask (int how,const sigset_t *set,sigset_t *oldset)
{
  return __rt_sigprocmask(how, set, oldset, NSIG/8);
}
weak_alias(__sigprocmask,sigprocmask)

int sigtimedwait(const sigset_t *set, siginfo_t *info,
                 struct timespec *timeout)
{
  return __rt_sigtimedwait(set, info, timeout, NSIG/8);
}

int sigwaitinfo(const sigset_t *set, siginfo_t *info)
{
  return __rt_sigtimedwait(set, info, NULL, NSIG/8);
}

#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL >= 4

static _syscall1(int,__ssetmask,int,newmask)
static _syscall0(int,__sgetmask)

int sigblock(int mask) /* BSD */
{
    return __ssetmask(mask | __sgetmask());
}

int sigsetmask(int newmask) /* BSD */
{
    return __ssetmask(newmask);
}
#endif

const char *const sys_siglist[] = {
#include "siglist.inc"
};
